import 'dart:math' as math;
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

  final bool ownsFd;

  RawPainter(this.fd, int width, int height, {this.ownsFd = false})
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

  Rect _clipRect() => _clips.last ?? Rect.fromLTWH(0, 0, width, height);

  @override
  void drawRect(Rect rect, Paint paint) {
    final tx = _translateX.last.round();
    final ty = _translateY.last.round();
    final sx = _scaleX.last;
    final sy = _scaleY.last;
    final l = (rect.left * sx).round() + tx;
    final t = (rect.top * sy).round() + ty;
    final w = (rect.width * sx).round();
    final h = (rect.height * sy).round();
    final clip = _clipRect();
    final cl = l.clamp(clip.left.round(), clip.right.round());
    final ct = t.clamp(clip.top.round(), clip.bottom.round());
    final cr = (l + w).clamp(clip.left.round(), clip.right.round());
    final cb = (t + h).clamp(clip.top.round(), clip.bottom.round());
    final cw = (cr - cl).round();
    final ch = (cb - ct).round();
    if (cw <= 0 || ch <= 0) return;
    if (paint.style == PaintStyle.stroke && paint.strokeWidth >= 1) {
      final sw = paint.strokeWidth.round().clamp(1, 4096);
      Rectangle(cl, ct, cw, sw, paint.color).draw(canvas);
      Rectangle(cl, (cb - sw).round(), cw, sw, paint.color).draw(canvas);
      final innerH = (ch - 2 * sw).clamp(0, 4096).round();
      if (innerH > 0) {
        Rectangle(cl, ct + sw, sw, innerH, paint.color).draw(canvas);
        Rectangle((cr - sw).round(), ct + sw, sw, innerH, paint.color).draw(canvas);
      }
      return;
    }
    Rectangle(cl, ct, cw, ch, paint.color).draw(canvas);
  }

  @override
  void drawRRect(Rect rect, double radiusX, double radiusY, Paint paint) {
    final tx = _translateX.last.round();
    final ty = _translateY.last.round();
    final sx = _scaleX.last;
    final sy = _scaleY.last;
    final r = Rect.fromLTRB(
      rect.left * sx + tx,
      rect.top * sy + ty,
      rect.right * sx + tx,
      rect.bottom * sy + ty,
    );
    final rx = (radiusX * sx).clamp(0, r.width / 2);
    final ry = (radiusY * sy).clamp(0, r.height / 2);
    final radius = (rx < ry ? rx : ry).round();
    if (radius <= 0) {
      drawRect(rect, paint);
      return;
    }
    _drawRRectPixels(r, radius, paint);
  }

  void _drawRRectPixels(Rect r, int radius, Paint paint) {
    final clip = _clipRect();
    final l = r.left.round();
    final t = r.top.round();
    final rt = r.right.round();
    final b = r.bottom.round();
    final sw = paint.style == PaintStyle.stroke ? paint.strokeWidth.round().clamp(1, 4096) : 0;
    for (var y = t; y < b; y++) {
      if (y < clip.top || y >= clip.bottom) continue;
      for (var x = l; x < rt; x++) {
        if (x < clip.left || x >= clip.right) continue;
        final inOuter = _isInRRect(x, y, r, radius);
        if (!inOuter) continue;
        if (sw > 0) {
          final inset = Rect.fromLTWH(
            (l + sw).toDouble(),
            (t + sw).toDouble(),
            (rt - l - 2 * sw).toDouble(),
            (b - t - 2 * sw).toDouble(),
          );
          final innerR = (radius - sw).clamp(0, 100000);
          if (inset.width <= 0 || inset.height <= 0) {
            canvas.setPixel(x, y, paint.color);
          } else {
            final inInner = _isInRRect(x, y, inset, innerR);
            if (!inInner) canvas.setPixel(x, y, paint.color);
          }
        } else {
          canvas.setPixel(x, y, paint.color);
        }
      }
    }
  }

  bool _isInRRect(int x, int y, Rect rect, int r) {
    final l = rect.left.round();
    final t = rect.top.round();
    final rt = rect.right.round();
    final b = rect.bottom.round();
    if (x < l || x >= rt || y < t || y >= b) return false;
    if (r <= 0) return true;
    // Center rectangle (non-corner area) is always inside.
    if (x >= l + r && x < rt - r) return true;
    if (y >= t + r && y < b - r) return true;
    // Corner circles.
    int cx, cy;
    if (x < l + r && y < t + r) {
      cx = l + r;
      cy = t + r;
    } else if (x >= rt - r && y < t + r) {
      cx = rt - r - 1;
      cy = t + r;
    } else if (x < l + r && y >= b - r) {
      cx = l + r;
      cy = b - r - 1;
    } else if (x >= rt - r && y >= b - r) {
      cx = rt - r - 1;
      cy = b - r - 1;
    } else {
      return true;
    }
    final dx = x - cx;
    final dy = y - cy;
    return dx * dx + dy * dy <= r * r;
  }

  @override
  void drawCircle(Offset center, double radius, Paint paint) {
    final tx = _translateX.last.round();
    final ty = _translateY.last.round();
    final sx = _scaleX.last;
    final sy = _scaleY.last;
    final cx = (center.dx * sx).round() + tx;
    final cy = (center.dy * sy).round() + ty;
    final rad = (radius * ((sx + sy) / 2)).round();
    final clip = _clipRect();
    if (paint.style == PaintStyle.stroke && paint.strokeWidth >= 1) {
      final sw = paint.strokeWidth.round();
      for (var y = cy - rad; y <= cy + rad; y++) {
        if (y < clip.top || y >= clip.bottom) continue;
        for (var x = cx - rad; x <= cx + rad; x++) {
          if (x < clip.left || x >= clip.right) continue;
          final d2 = (x - cx) * (x - cx) + (y - cy) * (y - cy);
          if (d2 <= rad * rad && d2 >= (rad - sw) * (rad - sw)) {
            canvas.setPixel(x, y, paint.color);
          }
        }
      }
      return;
    }
    for (var y = cy - rad; y <= cy + rad; y++) {
      if (y < clip.top || y >= clip.bottom) continue;
      for (var x = cx - rad; x <= cx + rad; x++) {
        if (x < clip.left || x >= clip.right) continue;
        if ((x - cx) * (x - cx) + (y - cy) * (y - cy) <= rad * rad) {
          canvas.setPixel(x, y, paint.color);
        }
      }
    }
  }

  @override
  void drawLine(Offset from, Offset to, Paint paint) {
    final tx = _translateX.last.round();
    final ty = _translateY.last.round();
    final sx = _scaleX.last;
    final sy = _scaleY.last;
    final x0 = (from.dx * sx).round() + tx;
    final y0 = (from.dy * sy).round() + ty;
    final x1 = (to.dx * sx).round() + tx;
    final y1 = (to.dy * sy).round() + ty;
    final clip = _clipRect();
    int dx = (x1 - x0).abs();
    int dy = (y1 - y0).abs();
    int sxStep = x0 < x1 ? 1 : -1;
    int syStep = y0 < y1 ? 1 : -1;
    int err = dx - dy;
    int x = x0, y = y0;
    while (true) {
      if (x >= clip.left && x < clip.right && y >= clip.top && y < clip.bottom) {
        canvas.setPixel(x, y, paint.color);
      }
      if (x == x1 && y == y1) break;
      final e2 = 2 * err;
      if (e2 > -dy) {
        err -= dy;
        x += sxStep;
      }
      if (e2 < dx) {
        err += dx;
        y += syStep;
      }
    }
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
    final px = (position.dx * sx).round() + tx;
    final py = (position.dy * sy).round() + ty;
    // Bitmap font is fixed 8x16; adapt via sx/sy for size not 14.
    // Simple approach: draw at transformed position with clipping per glyph.
    final clip = _clipRect();
    // Clipping is per-pixel in BitmapFont._drawGlyph via setPixel, so we
    // pass clipped check inside loop. Just ensure origin is within rough bounds
    // before drawing.
    if (px < clip.right && px + text.length * 8 * sx > clip.left &&
        py < clip.bottom && py + 16 * sy > clip.top) {
      _defaultFont.drawText(
        canvas,
        px,
        py,
        text,
        color ?? const Color(255, 255, 255),
      );
    }
  }

  @override
  void drawLinearGradient(Rect rect, Color color0, Color color1, {double angle = 0.0}) {
    final tx = _translateX.last.round();
    final ty = _translateY.last.round();
    final sx = _scaleX.last;
    final sy = _scaleY.last;
    final l = (rect.left * sx).round() + tx;
    final t = (rect.top * sy).round() + ty;
    final w = (rect.width * sx).round();
    final h = (rect.height * sy).round();
    final clip = _clipRect();
    final cl = l.clamp(clip.left.round(), clip.right.round());
    final ct = t.clamp(clip.top.round(), clip.bottom.round());
    final cr = (l + w).clamp(clip.left.round(), clip.right.round());
    final cb = (t + h).clamp(clip.top.round(), clip.bottom.round());
    if (cr <= cl || cb <= ct) return;
    // Fast path: horizontal (angle ~0)
    final isHorizontal = (angle % (2 * math.pi)).abs() < 0.01 ||
        (angle % (2 * math.pi) - math.pi).abs() < 0.01;
    final isVertical = (angle - math.pi / 2).abs() < 0.01 ||
        (angle - 3 * math.pi / 2).abs() < 0.01;
    for (var y = ct; y < cb; y++) {
      for (var x = cl; x < cr; x++) {
        double tt;
        if (isHorizontal) {
          tt = (x - l) / w.clamp(1, 1 << 30);
        } else if (isVertical) {
          tt = (y - t) / h.clamp(1, 1 << 30);
        } else {
          // Project onto angle vector.
          final dx = math.cos(angle);
          final dy = math.sin(angle);
          final dot = (x - l) * dx + (y - t) * dy;
          final len = w * dx.abs() + h * dy.abs();
          tt = (dot / len.clamp(1, 1 << 30)).clamp(0.0, 1.0);
        }
        final r = (color0.r + (color1.r - color0.r) * tt).round().clamp(0, 255);
        final g = (color0.g + (color1.g - color0.g) * tt).round().clamp(0, 255);
        final b = (color0.b + (color1.b - color0.b) * tt).round().clamp(0, 255);
        final a = (color0.a + (color1.a - color0.a) * tt).round().clamp(0, 255);
        canvas.setPixel(x, y, Color(r, g, b, a));
      }
    }
  }

  @override
  void drawImage(String filePath, double x, double y, {double? width, double? height}) {
    final tx = _translateX.last.round();
    final ty = _translateY.last.round();
    final sx = _scaleX.last;
    final sy = _scaleY.last;
    final dx = (x * sx).round() + tx;
    final dy = (y * sy).round() + ty;
    final dw = width != null ? (width * sx).round() : 16;
    final dh = height != null ? (height * sy).round() : 16;
    final clip = _clipRect();
    // Placeholder: keep old behavior but respect clip via drawRect.
    final rect = Rect.fromLTWH(dx.toDouble(), dy.toDouble(), dw.toDouble(), dh.toDouble());
    final cl = rect.left.clamp(clip.left, clip.right);
    final ct = rect.top.clamp(clip.top, clip.bottom);
    final cr = rect.right.clamp(clip.left, clip.right);
    final cb = rect.bottom.clamp(clip.top, clip.bottom);
    if (cr > cl && cb > ct) {
      Rectangle(cl.round(), ct.round(), (cr - cl).round(), (cb - ct).round(), const Color(0x60, 0x60, 0x70)).draw(canvas);
    }
  }

  @override
  Size measureText(
    String text, {
    double size = 14,
    String fontFamily = 'sans',
  }) {
    final base = _defaultFont.textWidth(text).toDouble();
    final h = _defaultFont.height.toDouble();
    // Scale relative to default 14px bitmap baseline.
    final scale = size / 14.0;
    return Size(base * scale, h * scale);
  }

  @override
  Rect measureTextBounds(
    String text, {
    double size = 14,
    String fontFamily = 'sans',
  }) {
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

  @override
  void flush() {
    if (!_disposed && fd >= 0) {
      try {
        writeToFd(fd, canvas.pixels);
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    if (!_disposed) {
      try {
        flush();
      } catch (_) {}
      if (ownsFd && fd >= 0) {
        try {
          closeFd(fd);
        } catch (_) {}
      }
      _disposed = true;
    }
  }
}
