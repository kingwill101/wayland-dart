import 'dart:ffi';
import 'dart:io' show Platform, stderr;

import 'package:dawn_dart/dawn_dart.dart';
import 'package:ffi/ffi.dart';
import 'package:skia_dart/skia_dart.dart';
import 'package:wayland/wayland.dart';

import '../drawing/color.dart';
import 'painter.dart';
import 'skia_text_engine.dart';

/// Process-wide Dawn/Graphite device shared by frame painters.
///
/// The Wayland layer still owns presentation. This backend renders with
/// Graphite and copies the completed GPU frame into the layer's SHM buffer.
class _DawnGraphiteRuntime {
  _DawnGraphiteRuntime._();

  late final WgpuInstance instance;
  late final WgpuAdapter adapter;
  late final WgpuDevice device;
  late final WgpuQueue queue;
  late final GraphiteContext context;

  static _DawnGraphiteRuntime create() {
    if (!wgpuInitialize()) {
      throw StateError('Dawn/WebGPU is unavailable');
    }

    final runtime = _DawnGraphiteRuntime._();
    runtime.instance = WgpuInstance.create();
    final adapter = runtime.instance.requestAdapter(WgpuBackendType.vulkan);
    if (adapter == null) {
      runtime.instance.dispose();
      throw StateError('Dawn could not find a Vulkan adapter');
    }
    runtime.adapter = adapter;
    final device = adapter.requestDevice();
    if (device == null) {
      adapter.dispose();
      runtime.instance.dispose();
      throw StateError('Dawn could not create a Vulkan device');
    }
    runtime.device = device;
    runtime.queue = device.getQueue();
    final context = GraphiteContext.makeDawn(
      procTable: WgpuProcTable.instance,
      instance: runtime.instance,
      device: device,
      queue: runtime.queue,
    );
    if (context == null) {
      runtime.queue.dispose();
      device.dispose();
      adapter.dispose();
      runtime.instance.dispose();
      throw StateError('Skia Graphite could not create a Dawn context');
    }
    runtime.context = context;
    return runtime;
  }

  static _DawnGraphiteRuntime? _shared;

  static _DawnGraphiteRuntime get shared => _shared ??= create();
}

/// Skia Graphite painter backed by Dawn/WebGPU.
///
/// This is deliberately separate from [GlesPainter]. It uses Vulkan first,
/// avoiding EGL, and keeps the existing SHM presentation contract while the
/// zero-copy Wayland dmabuf path is developed separately.
class DawnGraphitePainter implements Painter {
  DawnGraphitePainter(int fd, int width, int height)
    : _width = width,
      _height = height,
      _bufferSize = width * 4 * height,
      _mappedMemory = mmapFd(fd, width * 4 * height),
      _runtime = _DawnGraphiteRuntime.shared {
    final info = SkImageInfo(
      width: width,
      height: height,
      colorType: SkColorType.rgba8888,
      alphaType: SkAlphaType.premul,
    );
    _recorder = _runtime.context.makeRecorder();
    final surface = _recorder.makeRenderTarget(info);
    if (surface == null) {
      _recorder.dispose();
      munmap(_mappedMemory, _bufferSize);
      throw StateError('Dawn Graphite could not create a render target');
    }
    _surface = surface;
    _canvas = surface.canvas;
  }

  final int _width;
  final int _height;
  final int _bufferSize;
  final Pointer<Void> _mappedMemory;
  final _DawnGraphiteRuntime _runtime;
  late final GraphiteRecorder _recorder;
  late final SkSurface _surface;
  late final SkCanvas _canvas;
  final SkiaTextEngine _text = SkiaTextEngine.shared;
  bool _disposed = false;

  @override
  double get width => _width.toDouble();

  @override
  double get height => _height.toDouble();

  @override
  Size get size => Size(width, height);

  SkPaint _makePaint(Paint paint) {
    return SkPaint()
      ..color = SkColor(paint.color.toArgb8888())
      ..style = paint.style == PaintStyle.fill
          ? SkPaintStyle.fill
          : SkPaintStyle.stroke
      ..strokeWidth = paint.strokeWidth
      ..isAntiAlias = paint.antiAlias;
  }

  @override
  void clear(Color color) => _canvas.clear(SkColor(color.toArgb8888()));

  @override
  void drawRect(Rect rect, Paint paint) {
    final skPaint = _makePaint(paint);
    _canvas.drawRect(
      SkRect.fromLTRB(rect.left, rect.top, rect.right, rect.bottom),
      skPaint,
    );
    skPaint.dispose();
  }

  @override
  void drawRRect(Rect rect, double radiusX, double radiusY, Paint paint) {
    final skPaint = _makePaint(paint);
    _canvas.drawRoundRect(
      SkRect.fromLTRB(rect.left, rect.top, rect.right, rect.bottom),
      radiusX,
      radiusY,
      skPaint,
    );
    skPaint.dispose();
  }

  @override
  void drawCircle(Offset center, double radius, Paint paint) {
    final skPaint = _makePaint(paint);
    _canvas.drawCircle(center.dx, center.dy, radius, skPaint);
    skPaint.dispose();
  }

  @override
  void drawLine(Offset from, Offset to, Paint paint) {
    final skPaint = _makePaint(paint);
    _canvas.drawLine(from.dx, from.dy, to.dx, to.dy, skPaint);
    skPaint.dispose();
  }

  @override
  void drawArc(
    Rect oval,
    double startAngle,
    double sweepAngle,
    bool useCenter,
    Paint paint,
  ) {
    final skPaint = _makePaint(paint);
    _canvas.drawArc(
      SkRect.fromLTRB(oval.left, oval.top, oval.right, oval.bottom),
      startAngle,
      sweepAngle,
      useCenter,
      skPaint,
    );
    skPaint.dispose();
  }

  @override
  void drawText(
    String text,
    Offset position, {
    Color? color,
    double size = 14,
    String fontFamily = 'sans',
  }) {
    _text.drawText(
      _canvas,
      text,
      position.dx,
      position.dy,
      color: color,
      size: size,
      fontFamily: fontFamily,
    );
  }

  @override
  Size measureText(
    String text, {
    double size = 14,
    String fontFamily = 'sans',
  }) => _text.measureText(text, size: size, fontFamily: fontFamily);

  @override
  Rect measureTextBounds(
    String text, {
    double size = 14,
    String fontFamily = 'sans',
  }) => _text.measureTextBounds(text, size: size, fontFamily: fontFamily);

  @override
  double measureTextAdvance(
    String text, {
    double size = 14,
    String fontFamily = 'sans',
  }) => _text.measureTextAdvance(text, size: size, fontFamily: fontFamily);

  @override
  void drawImage(
    String filePath,
    double x,
    double y, {
    double? width,
    double? height,
  }) {
    SkData? data;
    SkImage? image;
    SkPixmap? pixels;
    Pointer<Uint8>? ownedPixels;
    final debugImages =
        Platform.environment['WAYLAND_DAWN_DEBUG_IMAGES'] == '1';
    try {
      data = SkData.fromFile(filePath);
      if (data == null) {
        if (debugImages) {
          stderr.writeln('[wt:dawn] image data missing path=$filePath');
        }
        return;
      }
      image = SkImage.fromEncoded(data);
      if (image == null) {
        if (debugImages) {
          stderr.writeln('[wt:dawn] image decode failed path=$filePath');
        }
        return;
      }
      // Encoded images decode to raster-backed SkImages. Graphite cannot draw
      // those directly: it requires a Graphite texture, and the current
      // skia_dart API does not expose a Dawn texture upload for SkImage.
      // Read the small tray/icon image and draw opaque runs as Graphite-safe
      // rectangles instead. This avoids the repeated "Couldn't convert
      // SkImage" / "Key context creation failed" warnings and preserves
      // transparency.
      pixels = SkPixmap();
      if (!image.peekPixels(pixels)) {
        // Some encoded images are lazy-backed and expose no direct pixel
        // pointer. Materialize those into a small CPU pixmap before turning
        // the pixels into Graphite-safe rectangles.
        final info = SkImageInfo(
          width: image.width,
          height: image.height,
          colorType: SkColorType.rgba8888,
          alphaType: SkAlphaType.premul,
        );
        ownedPixels = calloc<Uint8>(info.minByteSize);
        final decoded = SkPixmap.withParams(
          info,
          ownedPixels.cast(),
          info.minRowBytes,
        );
        if (!image.readPixelsIntoPixmap(decoded)) {
          decoded.dispose();
          if (debugImages) {
            stderr.writeln(
              '[wt:dawn] image pixel read failed path=$filePath '
              'decoded=${image.width}x${image.height}',
            );
          }
          return;
        }
        pixels.dispose();
        pixels = decoded;
        if (debugImages) {
          stderr.writeln(
            '[wt:dawn] image materialized path=$filePath '
            'decoded=${image.width}x${image.height}',
          );
        }
      }
      var nonTransparentPixels = 0;
      var drawRuns = 0;

      final dstW = width ?? image.width.toDouble();
      final dstH = height ?? image.height.toDouble();
      final sx = dstW / pixels.width;
      final sy = dstH / pixels.height;
      for (var py = 0; py < pixels.height; py++) {
        var runStart = -1;
        var runColor = 0;
        for (var px = 0; px <= pixels.width; px++) {
          final color = px < pixels.width ? pixels.getPixelColor(px, py) : null;
          final value = color?.value ?? 0;
          final alpha = color?.alpha ?? 0;
          if (alpha != 0) {
            nonTransparentPixels++;
          }
          final same = runStart >= 0 && value == runColor && alpha != 0;
          if (alpha != 0 && (runStart < 0 || same)) {
            runStart = runStart < 0 ? px : runStart;
            runColor = value;
            continue;
          }
          if (runStart >= 0) {
            final skColor = SkColor(runColor);
            final paint = _makePaint(
              Paint()
                ..color = Color(
                  skColor.red,
                  skColor.green,
                  skColor.blue,
                  skColor.alpha,
                ),
            );
            _canvas.drawRect(
              SkRect.fromLTRB(
                x + runStart * sx,
                y + py * sy,
                x + px * sx,
                y + (py + 1) * sy,
              ),
              paint,
            );
            paint.dispose();
            drawRuns++;
            runStart = -1;
          }
          if (alpha != 0) {
            runStart = px;
            runColor = value;
          }
        }
      }
      if (debugImages) {
        stderr.writeln(
          '[wt:dawn] image path=$filePath decoded=${pixels.width}x${pixels.height} '
          'nonTransparent=$nonTransparentPixels runs=$drawRuns',
        );
      }
    } catch (error) {
      stderr.writeln('[wt:dawn] drawImage failed: $error');
    } finally {
      pixels?.dispose();
      if (ownedPixels != null) calloc.free(ownedPixels);
      image?.dispose();
      data?.dispose();
    }
  }

  @override
  void clipRect(Rect rect) => _canvas.clipRect(
    SkRect.fromLTRB(rect.left, rect.top, rect.right, rect.bottom),
  );

  @override
  void save() => _canvas.save();

  @override
  void restore() => _canvas.restore();

  @override
  void translate(double dx, double dy) => _canvas.translate(dx, dy);

  @override
  void scale(double sx, double sy) => _canvas.scale(sx, sy);

  @override
  void drawLinearGradient(
    Rect rect,
    Color color0,
    Color color1, {
    double angle = 0.0,
  }) {
    // Gradient shader plumbing belongs in the shared Graphite painter layer;
    // retain a visible result until that API is added.
    drawRect(rect, Paint()..color = color0);
  }

  @override
  void flush() {
    if (_disposed) return;
    final recording = _recorder.snap();
    if (recording == null ||
        !_runtime.context.insertRecording(
          GraphiteInsertRecordingInfo(recording: recording),
        )) {
      recording?.dispose();
      throw StateError('Dawn Graphite failed to insert frame recording');
    }

    SkBitmap? bitmap;
    _runtime.context.asyncRescaleAndReadPixelsFromSurface(
      SkIRect.fromLTRB(0, 0, _width, _height),
      _surface,
      SkImageInfo(
        width: _width,
        height: _height,
        colorType: SkColorType.rgba8888,
        alphaType: SkAlphaType.premul,
      ),
      SkImageRescaleGamma.src,
      SkImageRescaleMode.linear,
      (result) => bitmap = result,
    );
    if (!_runtime.context.submit(const GraphiteSubmitInfo(syncToCpu: true)) ||
        bitmap == null) {
      bitmap?.dispose();
      throw StateError('Dawn Graphite failed to read back frame');
    }

    final pixmap = SkPixmap();
    try {
      if (!bitmap!.peekPixels(pixmap)) {
        throw StateError('Dawn Graphite returned no readable pixels');
      }
      final source = pixmap.getAddr8().asTypedList(_bufferSize);
      final destination = _mappedMemory.cast<Uint8>().asTypedList(_bufferSize);
      destination.setAll(0, source);
    } finally {
      pixmap.dispose();
      bitmap!.dispose();
    }
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _surface.dispose();
    _recorder.dispose();
    munmap(_mappedMemory, _bufferSize);
  }
}
