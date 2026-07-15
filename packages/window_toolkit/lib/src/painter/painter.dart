import '../drawing/color.dart';

class Offset {
  final double dx, dy;
  const Offset(this.dx, this.dy);
  const Offset.zero() : dx = 0, dy = 0;
}

class Size {
  final double width, height;
  const Size(this.width, this.height);
  const Size.zero() : width = 0, height = 0;
}

class Rect {
  final double left, top, right, bottom;
  const Rect.fromLTRB(this.left, this.top, this.right, this.bottom);
  const Rect.fromLTWH(double left, double top, double width, double height)
      : left = left,
        top = top,
        right = left + width,
        bottom = top + height;

  double get width => right - left;
  double get height => bottom - top;
  Offset get center => Offset((left + right) / 2, (top + bottom) / 2);
  Rect shift(double dx, double dy) =>
      Rect.fromLTRB(left + dx, top + dy, right + dx, bottom + dy);

  bool contains(double x, double y) =>
      x >= left && x < right && y >= top && y < bottom;
}

enum PaintStyle { fill, stroke }

class Paint {
  Color color = const Color(255, 255, 255);
  PaintStyle style = PaintStyle.fill;
  double strokeWidth = 1.0;
  bool antiAlias = true;
}

abstract class Painter {
  Size get size;
  double get width;
  double get height;

  void clear(Color color);

  void drawRect(Rect rect, Paint paint);
  void drawCircle(Offset center, double radius, Paint paint);
  void drawLine(Offset from, Offset to, Paint paint);

  /// Rounded rectangle. Default implementation falls back to [drawRect].
  void drawRRect(Rect rect, double radiusX, double radiusY, Paint paint) {
    drawRect(rect, paint);
  }

  void drawText(String text, Offset position, {Color? color, double size = 14, String fontFamily = 'sans'});

  /// Typographic size for layout: width is the advance (not ink bounds).
  Size measureText(String text,
      {double size = 14, String fontFamily = 'sans'});

  /// Typographic advance (where the next glyph would start). Defaults to
  /// [measureText].width for painters that don't distinguish advance/bounds.
  double measureTextAdvance(String text,
      {double size = 14, String fontFamily = 'sans'}) {
    return measureText(text, size: size, fontFamily: fontFamily).width;
  }

  /// Glyph ink bounds relative to the [drawText] origin.
  ///
  /// For Skia this is baseline-relative (top is typically negative). For
  /// bitmap fonts the origin is top-left so [Rect.top] is 0.
  /// Use this to center text: origin = boxCenter - bounds.center.
  ///
  /// **Do not use bounds.width for horizontal layout of bar modules** — it can
  /// be much wider than the advance. Prefer [measureText] / [measureTextAdvance].
  Rect measureTextBounds(String text,
      {double size = 14, String fontFamily = 'sans'}) {
    final s = measureText(text, size: size, fontFamily: fontFamily);
    return Rect.fromLTWH(0, 0, s.width, s.height);
  }

  /// Draw a PNG/JPEG image from [filePath] at (x, y) scaled to [width]x[height].
  /// If [width]/[height] are omitted the image's native dimensions are used.
  void drawImage(String filePath, double x, double y, {double? width, double? height});

  void clipRect(Rect rect);

  void save();
  void restore();
  void translate(double dx, double dy);
  void scale(double sx, double sy);

  /// Flush any pending drawing to the backing store (e.g. PBuffer → SHM).
  void flush() {}

  /// Release per-frame resources. Called after [flush] on every paint cycle.
  void dispose() {}
}
