import 'dart:ffi';

import 'package:skia_dart/skia_dart.dart';
import 'package:wayland/wayland.dart';

import '../drawing/color.dart';
import '../painter/skia_text_engine.dart';

class SkiaRenderer {
  int _fd = -1;
  int _bufferSize = 0;
  Pointer<Void>? _mappedMemory;
  SkSurface? _surface;
  SkCanvas? _canvas;
  final SkiaTextEngine _text = SkiaTextEngine.shared;

  int get width => _surface?.width ?? 0;
  int get height => _surface?.height ?? 0;

  void ensureBuffer(int fd, int width, int height) {
    final stride = width * 4;
    final size = stride * height;

    if (_surface != null && _fd == fd && _bufferSize >= size) return;

    dispose();

    _fd = fd;
    _bufferSize = size;

    _mappedMemory = mmapFd(fd, size);

    final imageInfo = SkImageInfo(
      width: width,
      height: height,
      colorType: SkColorType.rgba8888,
      alphaType: SkAlphaType.premul,
    );

    _surface = SkSurface.rasterDirect(imageInfo, _mappedMemory!, stride);

    if (_surface == null) {
      throw Exception('Failed to create SkSurface for SHM buffer');
    }

    _canvas = _surface!.canvas;
  }

  SkCanvas get canvas {
    if (_canvas == null) throw StateError('ensureBuffer() not called');
    return _canvas!;
  }

  void drawText(
    String text,
    double x,
    double y, {
    int color = 0xFFFFFFFF,
    double size = 14,
  }) {
    _text.drawText(
      canvas,
      text,
      x,
      y,
      color: Color.fromArgb8888(color),
      size: size,
    );
  }

  void drawRect(double x, double y, double w, double h, int color) {
    final paint = SkPaint();
    paint.color = SkColor(color);
    paint.style = SkPaintStyle.fill;
    canvas.drawRect(SkRect.fromLTRB(x, y, x + w, y + h), paint);
    paint.dispose();
  }

  void drawRoundRect(
    double x,
    double y,
    double w,
    double h,
    double radius,
    int color,
  ) {
    final paint = SkPaint();
    paint.color = SkColor(color);
    paint.style = SkPaintStyle.fill;
    paint.isAntiAlias = true;
    canvas.drawRoundRect(
      SkRect.fromLTRB(x, y, x + w, y + h),
      radius,
      radius,
      paint,
    );
    paint.dispose();
  }

  void clear(int color) {
    canvas.clear(SkColor(color));
  }

  void flush() {
    _surface?.makeImageSnapshot()?.dispose();
  }

  void dispose() {
    _surface?.dispose();
    _surface = null;
    _canvas = null;
    _text.dispose();
    if (_mappedMemory != null && _mappedMemory != nullptr) {
      munmap(_mappedMemory!, _bufferSize);
      _mappedMemory = null;
    }
    _fd = -1;
    _bufferSize = 0;
  }
}
