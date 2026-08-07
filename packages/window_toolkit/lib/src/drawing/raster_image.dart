import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:gl/gl.dart';
import 'package:skia_dart/skia_dart.dart';

import '../font/font_database.dart';
import '../font/font.dart';
import '../painter/skia_text_engine.dart';
import 'color.dart';

/// CPU-backed RGBA pixel buffer — analogue of Qt's QImage.
class RasterImage {
  final int width;
  final int height;
  final Uint8List pixels; // RGBA, row 0 = top

  int get rowBytes => width * 4;

  RasterImage(this.width, this.height) : pixels = Uint8List(width * height * 4);

  void clear([Color? color]) {
    if (color == null) {
      pixels.fillRange(0, pixels.length, 0);
      return;
    }
    final r = color.r;
    final g = color.g;
    final b = color.b;
    final a = color.a;
    for (var i = 0; i < pixels.length; i += 4) {
      pixels[i] = r; pixels[i+1] = g; pixels[i+2] = b; pixels[i+3] = a;
    }
  }

  void drawRect(double x, double y, double w, double h, Color color) {
    final ix = x.round().clamp(0, width - 1);
    final iy = y.round().clamp(0, height - 1);
    final iw = (x + w).round().clamp(0, width) - ix;
    final ih = (y + h).round().clamp(0, height) - iy;
    for (var row = iy; row < iy + ih; row++) {
      for (var col = ix; col < ix + iw; col++) {
        final i = (row * width + col) * 4;
        pixels[i] = color.r; pixels[i+1] = color.g;
        pixels[i+2] = color.b; pixels[i+3] = color.a;
      }
    }
  }

  void drawLine(double x0, double y0, double x1, double y1, Color color) {
    int ix0 = x0.round().clamp(0, width - 1);
    int iy0 = y0.round().clamp(0, height - 1);
    int ix1 = x1.round().clamp(0, width - 1);
    int iy1 = y1.round().clamp(0, height - 1);
    final dx = (ix1 - ix0).abs();
    final dy = -(iy1 - iy0).abs();
    final sx = ix0 < ix1 ? 1 : -1;
    final sy = iy0 < iy1 ? 1 : -1;
    var err = dx + dy;
    while (true) {
      final i = (iy0 * width + ix0) * 4;
      pixels[i] = color.r; pixels[i+1] = color.g;
      pixels[i+2] = color.b; pixels[i+3] = color.a;
      if (ix0 == ix1 && iy0 == iy1) break;
      final e2 = 2 * err;
      if (e2 >= dy) { err += dy; ix0 += sx; }
      if (e2 <= dx) { err += dx; iy0 += sy; }
    }
  }

  void drawCircle(double cx, double cy, double radius, Color color) {
    final r2 = radius * radius;
    final ix = (cx - radius).round().clamp(0, width - 1);
    final iy = (cy - radius).round().clamp(0, height - 1);
    final ix2 = (cx + radius).round().clamp(0, width - 1);
    final iy2 = (cy + radius).round().clamp(0, height - 1);
    for (var row = iy; row <= iy2; row++) {
      for (var col = ix; col <= ix2; col++) {
        final d2 = (col - cx)*(col - cx) + (row - cy)*(row - cy);
        if (d2 <= r2) {
          final i = (row * width + col) * 4;
          pixels[i] = color.r; pixels[i+1] = color.g;
          pixels[i+2] = color.b; pixels[i+3] = color.a;
        }
      }
    }
  }

  /// Draw text using Skia into a self-managed raster surface.
  /// Reads pixels back via image snapshot for reliable data.
  void drawText(
    String text,
    double x,
    double y, {
    Font? font,
    Color color = const Color(255, 255, 255),
  }) {
    if (text.isEmpty || width <= 0 || height <= 0) return;

    final resolved = FontDatabase.instance.resolveRequest(
      font ?? Font.ui(pixelSize: FontDatabase.instance.defaultPixelSize),
    );

    // Use rasterDirect (same as SkiaPainter). Allocate native buffer,
    // render text, then copy back to our pixel list.
    final nativePixels = calloc<Uint8>(pixels.length);
    for (var i = 0; i < pixels.length; i++) {
      nativePixels[i] = 0;
    }

    final info = SkImageInfo(
      width: width, height: height,
      colorType: SkColorType.rgba8888,
      alphaType: SkAlphaType.premul,
    );
    final surface = SkSurface.rasterDirect(info, nativePixels.cast(), rowBytes);
    if (surface != null) {
      SkiaTextEngine.shared.drawText(
        surface.canvas, text, x, y,
        color: color,
        size: resolved.pixelSize,
        fontFamily: resolved.family,
      );
      surface.dispose();
      for (var i = 0; i < pixels.length; i++) {
        pixels[i] = nativePixels[i];
      }
    }
    calloc.free(nativePixels);
  }

  /// Extract alpha channel for GL texture. GL_NEAREST filtering.
  Texture toTexture() {
    final alpha = Uint8List(width * height);
    for (var i = 0; i < width * height; i++) {
      alpha[i] = pixels[i * 4 + 3];
    }
    return Texture.fromAlpha(alpha, width, height, smooth: false);
  }
}
