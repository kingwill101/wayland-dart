import 'dart:io' show stderr;
import 'dart:ffi';

import 'package:skia_dart/skia_dart.dart';
import 'package:wayland/wayland.dart';

import '../drawing/color.dart';

import 'painter.dart';
import 'skia_text_engine.dart';

class SkiaPainter implements Painter {
  @override
  double get width => _width.toDouble();

  @override
  double get height => _height.toDouble();

  @override
  Size get size => Size(width, height);

  final int _width;
  final int _height;
  final int fd;
  final Pointer<Void> _mappedMemory;
  final int _bufferSize;
  final SkSurface _surface;
  final SkCanvas _canvas;

  /// Shared across all painters — never create a FontMgr per frame.
  final SkiaTextEngine _text = SkiaTextEngine.shared;

  SkiaPainter._({
    required this.fd,
    required int width,
    required int height,
    required Pointer<Void> mappedMemory,
    required int bufferSize,
    required SkSurface surface,
    required SkCanvas canvas,
  }) : _width = width,
       _height = height,
       _mappedMemory = mappedMemory,
       _bufferSize = bufferSize,
       _surface = surface,
       _canvas = canvas;

  factory SkiaPainter(int fd, int width, int height) {
    final bufferSize = width * 4 * height;
    final mappedMemory = mmapFd(fd, bufferSize);
    final imageInfo = SkImageInfo(
      width: width,
      height: height,
      colorType: SkColorType.rgba8888,
      alphaType: SkAlphaType.premul,
    );
    final surface = SkSurface.rasterDirect(imageInfo, mappedMemory, width * 4);
    if (surface == null) {
      munmap(mappedMemory, bufferSize);
      throw Exception('Failed to create SkSurface for SHM buffer');
    }
    return SkiaPainter._(
      fd: fd,
      width: width,
      height: height,
      mappedMemory: mappedMemory,
      bufferSize: bufferSize,
      surface: surface,
      canvas: surface.canvas,
    );
  }

  SkPaint _makePaint(Paint paint) {
    final skPaint = SkPaint();
    skPaint.color = SkColor(paint.color.toArgb8888());
    skPaint.style = paint.style == PaintStyle.fill
        ? SkPaintStyle.fill
        : SkPaintStyle.stroke;
    skPaint.strokeWidth = paint.strokeWidth;
    skPaint.isAntiAlias = paint.antiAlias;
    return skPaint;
  }

  @override
  void clear(Color color) {
    _canvas.clear(SkColor(color.toArgb8888()));
  }

  @override
  void drawRect(Rect rect, Paint paint) {
    final skPaint = _makePaint(paint);
    final skRect = SkRect.fromLTRB(
      rect.left,
      rect.top,
      rect.right,
      rect.bottom,
    );
    _canvas.drawRect(skRect, skPaint);
    skPaint.dispose();
  }

  @override
  void drawRRect(Rect rect, double radiusX, double radiusY, Paint paint) {
    final skPaint = _makePaint(paint);
    final skRect = SkRect.fromLTRB(
      rect.left,
      rect.top,
      rect.right,
      rect.bottom,
    );
    _canvas.drawRoundRect(skRect, radiusX, radiusY, skPaint);
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
    final skOval = SkRect.fromLTRB(
      oval.left,
      oval.top,
      oval.right,
      oval.bottom,
    );
    _canvas.drawArc(skOval, startAngle, sweepAngle, useCenter, skPaint);
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
  void drawLinearGradient(
    Rect rect,
    Color color0,
    Color color1, {
    double angle = 0.0,
  }) {
    drawRect(rect, Paint()..color = color0);
  }

  @override
  void drawImage(
    String filePath,
    double x,
    double y, {
    double? width,
    double? height,
  }) {
    try {
      final data = SkData.fromFile(filePath);
      if (data == null) return;
      final image = SkImage.fromEncoded(data);
      if (image == null) {
        data.dispose();
        return;
      }
      final imageW = image.width.toDouble();
      final imageH = image.height.toDouble();
      final dstW = width ?? imageW;
      final dstH = height ?? imageH;
      final dst = SkRect.fromLTRB(x, y, x + dstW, y + dstH);
      _canvas.drawImageRect(image, dst, sampling: const SkSamplingOptions());
      image.dispose();
      data.dispose();
    } catch (e) {
      stderr.writeln('[wt] drawImage failed: $e');
    }
  }

  @override
  Size measureText(
    String text, {
    double size = 14,
    String fontFamily = 'sans',
  }) {
    return _text.measureText(text, size: size, fontFamily: fontFamily);
  }

  @override
  Rect measureTextBounds(
    String text, {
    double size = 14,
    String fontFamily = 'sans',
  }) {
    return _text.measureTextBounds(text, size: size, fontFamily: fontFamily);
  }

  @override
  double measureTextAdvance(
    String text, {
    double size = 14,
    String fontFamily = 'sans',
  }) {
    return _text.measureTextAdvance(text, size: size, fontFamily: fontFamily);
  }

  @override
  void clipRect(Rect rect) {
    final r = SkRect.fromLTRB(rect.left, rect.top, rect.right, rect.bottom);
    _canvas.clipRect(r);
  }

  @override
  void save() {
    _canvas.save();
  }

  @override
  void restore() {
    _canvas.restore();
  }

  @override
  void translate(double dx, double dy) {
    _canvas.translate(dx, dy);
  }

  @override
  void scale(double sx, double sy) {
    _canvas.scale(sx, sy);
  }

  @override
  void flush() {
    _surface.makeImageSnapshot()?.dispose();
  }

  @override
  void dispose() {
    // Do not dispose the shared text engine.
    _surface.dispose();
    munmap(_mappedMemory, _bufferSize);
  }
}
