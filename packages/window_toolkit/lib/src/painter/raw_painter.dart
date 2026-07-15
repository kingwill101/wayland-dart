import 'dart:typed_data';

import 'package:wayland/wayland.dart';

import '../drawing/bitmap_font.dart';
import '../drawing/drawing.dart';
import 'painter.dart';

class RawPainter implements Painter {
  final int _width;
  final int _height;

  @override
  double get width => _width.toDouble();
  @override
  double get height => _height.toDouble();

  final int fd;
  final Canvas canvas;

  BitmapFont? _font;
  final List<double> _translateX = [0];
  final List<double> _translateY = [0];
  final List<double> _scaleX = [1];
  final List<double> _scaleY = [1];
  final List<Rect?> _clips = [null];
  bool _disposed = false;

  BitmapFont get _defaultFont => _font ??= BitmapFont.createDefault();

  RawPainter(this.fd, int width, int height)
    : _width = width,
      _height = height,
      canvas = Canvas(width, height, PixelFormat.argb8888);

  @override
  Size get size => Size(width, height);

  @override
  void clear(Color color) {
    final argb = color.toArgb8888();
    final view = Uint32List.view(canvas.pixels.buffer);
    view.fillRange(0, width.round() * height.round(), argb);
  }

  @override
  void drawRect(Rect rect, Paint paint) {
    final tx = _translateX.last.round();
    final ty = _translateY.last.round();
    final sx = _scaleX.last;
    final sy = _scaleY.last;
    Rectangle(
      (rect.left * sx).round() + tx,
      (rect.top * sy).round() + ty,
      (rect.width * sx).round(),
      (rect.height * sy).round(),
      paint.color,
    ).draw(canvas);
  }

  @override
  void drawRRect(Rect rect, double radiusX, double radiusY, Paint paint) {
    // Raw painter has no rounded-rect primitive — approximate with a rect.
    drawRect(rect, paint);
  }

  @override
  void drawCircle(Offset center, double radius, Paint paint) {
    final tx = _translateX.last.round();
    final ty = _translateY.last.round();
    final sx = _scaleX.last;
    final sy = _scaleY.last;
    Circle(
      (center.dx * sx).round() + tx,
      (center.dy * sy).round() + ty,
      (radius * ((sx + sy) / 2)).round(),
      paint.color,
    ).draw(canvas);
  }

  @override
  void drawLine(Offset from, Offset to, Paint paint) {
    final tx = _translateX.last.round();
    final ty = _translateY.last.round();
    final sx = _scaleX.last;
    final sy = _scaleY.last;
    Line(
      (from.dx * sx).round() + tx,
      (from.dy * sy).round() + ty,
      (to.dx * sx).round() + tx,
      (to.dy * sy).round() + ty,
      paint.color,
    ).draw(canvas);
  }

  @override
  void drawText(
    String text,
    Offset position, {
    Color? color,
    double size = 14,
    String fontFamily = 'sans',
  }) {
    final tx = _translateX.last.round();
    final ty = _translateY.last.round();
    final sx = _scaleX.last;
    final sy = _scaleY.last;
    _defaultFont.drawText(
      canvas,
      (position.dx * sx).round() + tx,
      (position.dy * sy).round() + ty,
      text,
      color ?? const Color(255, 255, 255),
    );
  }

  @override
  void drawLinearGradient(Rect rect, Color color0, Color color1,
      {double angle = 0.0}) {
    drawRect(rect, Paint()..color = color0);
  }

  @override
  void drawImage(String filePath, double x, double y, {double? width, double? height}) {
    // RawPainter does not support image rendering; draw a placeholder.
    final w = width ?? 16;
    final h = height ?? 16;
    drawRect(Rect.fromLTWH(x, y, w, h), Paint()..color = const Color(0x60, 0x60, 0x70));
  }

  @override
  Size measureText(
    String text, {
    double size = 14,
    String fontFamily = 'sans',
  }) {
    return Size(
      _defaultFont.textWidth(text).toDouble(),
      _defaultFont.height.toDouble(),
    );
  }

  @override
  Rect measureTextBounds(
    String text, {
    double size = 14,
    String fontFamily = 'sans',
  }) {
    // Bitmap font draws from top-left, not baseline.
    final s = measureText(text, size: size, fontFamily: fontFamily);
    return Rect.fromLTWH(0, 0, s.width, s.height);
  }

  @override
  double measureTextAdvance(
    String text, {
    double size = 14,
    String fontFamily = 'sans',
  }) {
    return measureText(text, size: size, fontFamily: fontFamily).width;
  }

  @override
  void clipRect(Rect rect) {
    final transformed = Rect.fromLTRB(
      rect.left * _scaleX.last + _translateX.last,
      rect.top * _scaleY.last + _translateY.last,
      rect.right * _scaleX.last + _translateX.last,
      rect.bottom * _scaleY.last + _translateY.last,
    );
    final current = _clips.last;
    if (current == null) {
      _clips[_clips.length - 1] = transformed;
    } else {
      final nx = transformed.left > current.left ? transformed.left : current.left;
      final ny = transformed.top > current.top ? transformed.top : current.top;
      final nr = transformed.right < current.right ? transformed.right : current.right;
      final nb = transformed.bottom < current.bottom ? transformed.bottom : current.bottom;
      _clips[_clips.length - 1] = Rect.fromLTRB(nx, ny, nr, nb);
    }
  }

  @override
  void save() {
    _translateX.add(_translateX.last);
    _translateY.add(_translateY.last);
    _scaleX.add(_scaleX.last);
    _scaleY.add(_scaleY.last);
    _clips.add(_clips.last);
  }

  @override
  void restore() {
    if (_translateX.length > 1) {
      _translateX.removeLast();
      _translateY.removeLast();
      _scaleX.removeLast();
      _scaleY.removeLast();
      _clips.removeLast();
    }
  }

  @override
  void translate(double dx, double dy) {
    _translateX.last += dx;
    _translateY.last += dy;
  }

  @override
  void scale(double sx, double sy) {
    _scaleX.last *= sx;
    _scaleY.last *= sy;
  }

  void flush() {
    if (!_disposed) {
      writeToFd(fd, canvas.pixels);
    }
  }

  void dispose() {
    if (!_disposed) {
      flush();
      closeFd(fd);
      _disposed = true;
    }
  }
}
