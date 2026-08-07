/// Geometry primitives for widget layout.
library;

import 'dart:math' as math;

/// The axis of a layout (horizontal or vertical).
enum Axis { horizontal, vertical }

/// Whether an enum value is horizontal.
bool isHorizontal(Axis a) => a == Axis.horizontal;

/// An offset in layout units.
class Offset {
  final double dx;
  final double dy;
  const Offset(this.dx, this.dy);
  static const zero = Offset(0, 0);

  @pragma('vm:prefer-inline')
  Offset operator +(Offset other) => Offset(dx + other.dx, dy + other.dy);

  @pragma('vm:prefer-inline')
  Offset operator -(Offset other) => Offset(dx - other.dx, dy - other.dy);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Offset && dx == other.dx && dy == other.dy;
  @override
  int get hashCode => Object.hash(dx, dy);
  @override
  String toString() => 'Offset($dx, $dy)';
}

/// A 2D extent.
class Size {
  final double width;
  final double height;
  const Size(this.width, this.height);
  static const zero = Size(0, 0);

  @pragma('vm:prefer-inline')
  Size operator +(Size other) => Size(width + other.width, height + other.height);

  @pragma('vm:prefer-inline')
  Size operator -(Size other) => Size(width - other.width, height - other.height);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Size && width == other.width && height == other.height;
  @override
  int get hashCode => Object.hash(width, height);
  @override
  String toString() => 'Size($width, $height)';
}

/// A rectangle.
class Rect {
  final double left;
  final double top;
  final double width;
  final double height;

  const Rect.fromLTWH(this.left, this.top, this.width, this.height);

  /// Pre-compute [right] and [bottom] for hot-path access.
  /// Use [fromLTWH] when you need cached right/bottom.
  const Rect.fromLTRB(double l, double t, double r, double b)
      : left = l,
        top = t,
        width = r - l,
        height = b - t;

  Rect.fromOffsetAndSize(Offset offset, Size size)
      : left = offset.dx,
        top = offset.dy,
        width = size.width,
        height = size.height;

  @pragma('vm:prefer-inline')
  double get right => left + width;

  @pragma('vm:prefer-inline')
  double get bottom => top + height;

  @pragma('vm:prefer-inline')
  Offset get offset => Offset(left, top);

  @pragma('vm:prefer-inline')
  Size get size => Size(width, height);

  @pragma('vm:prefer-inline')
  Rect shift(double dx, double dy) =>
      Rect.fromLTWH(left + dx, top + dy, width, height);

  @pragma('vm:prefer-inline')
  bool containsPoint(double x, double y) =>
      x >= left && x < right && y >= top && y < bottom;

  @override
  String toString() => 'Rect.fromLTWH($left, $top, $width, $height)';
}

/// Layout constraints: min/max width/height.
class BoxConstraints {
  final double minWidth;
  final double maxWidth;
  final double minHeight;
  final double maxHeight;

  const BoxConstraints({
    this.minWidth = 0,
    this.maxWidth = double.infinity,
    this.minHeight = 0,
    this.maxHeight = double.infinity,
  });

  const BoxConstraints.tightFor({double? width, double? height})
      : minWidth = width ?? 0,
        maxWidth = width ?? double.infinity,
        minHeight = height ?? 0,
        maxHeight = height ?? double.infinity;

  BoxConstraints.tightForSize(Size size)
      : minWidth = size.width,
        maxWidth = size.width,
        minHeight = size.height,
        maxHeight = size.height;

  static const tight = BoxConstraints();

  @pragma('vm:prefer-inline')
  bool get hasBoundedWidth => maxWidth < double.infinity;

  @pragma('vm:prefer-inline')
  bool get hasBoundedHeight => maxHeight < double.infinity;

  @pragma('vm:prefer-inline')
  bool get isTight => minWidth == maxWidth && minHeight == maxHeight;

  @pragma('vm:prefer-inline')
  bool get isNormalized =>
      minWidth <= maxWidth &&
      minHeight <= maxHeight &&
      minWidth >= 0 &&
      minHeight >= 0 &&
      maxWidth >= 0 &&
      maxHeight >= 0;

  /// Constrain [size] to fit within these constraints.
  @pragma('vm:prefer-inline')
  Size constrain(Size size) {
    return Size(
      size.width < minWidth
          ? minWidth
          : size.width > maxWidth ? maxWidth : size.width,
      size.height < minHeight
          ? minHeight
          : size.height > maxHeight ? maxHeight : size.height,
    );
  }

  /// Tighten constraints to a specific size.
  @pragma('vm:prefer-inline')
  BoxConstraints tighten({double? width, double? height}) {
    return BoxConstraints(
      minWidth: width ?? minWidth,
      maxWidth: width ?? maxWidth,
      minHeight: height ?? minHeight,
      maxHeight: height ?? maxHeight,
    );
  }

  /// Loosen constraints (set min to 0).
  @pragma('vm:prefer-inline')
  BoxConstraints loosen() {
    return BoxConstraints(
      minWidth: 0,
      maxWidth: maxWidth,
      minHeight: 0,
      maxHeight: maxHeight,
    );
  }

  /// Intersect this with [constraints] (like Flutter's `enforce`).
  @pragma('vm:prefer-inline')
  BoxConstraints enforce(BoxConstraints constraints) {
    return BoxConstraints(
      minWidth: minWidth.clamp(constraints.minWidth, constraints.maxWidth),
      maxWidth: maxWidth.clamp(constraints.minWidth, constraints.maxWidth),
      minHeight: minHeight.clamp(constraints.minHeight, constraints.maxHeight),
      maxHeight: maxHeight.clamp(constraints.minHeight, constraints.maxHeight),
    );
  }

  /// Deflate by [insets] (subtract padding from constraints).
  @pragma('vm:prefer-inline')
  BoxConstraints deflate(EdgeInsets insets) {
    final h = insets.horizontal;
    final v = insets.vertical;
    return BoxConstraints(
      minWidth: math.max(0, minWidth - h),
      maxWidth: maxWidth.isFinite ? math.max(0, maxWidth - h) : double.infinity,
      minHeight: math.max(0, minHeight - v),
      maxHeight: maxHeight.isFinite ? math.max(0, maxHeight - v) : double.infinity,
    );
  }

  @pragma('vm:prefer-inline')
  double constrainWidth(double w) => w.clamp(minWidth, maxWidth).toDouble();

  @pragma('vm:prefer-inline')
  double constrainHeight(double h) => h.clamp(minHeight, maxHeight).toDouble();

  @override
  String toString() =>
      'BoxConstraints($minWidth ≤ w ≤ $maxWidth, $minHeight ≤ h ≤ $maxHeight)';
}

/// Result of a hit-test walk.
class HitTestResult {
  final List<HitTestEntry> path = [];
  bool get anyHit => path.isNotEmpty;

  void add(HitTestEntry entry) => path.add(entry);
  void clear() => path.clear();
}

class HitTestEntry {
  final Object target;
  final double localX;
  final double localY;
  HitTestEntry(this.target, this.localX, this.localY);
}

/// Edge insets — like Flutter's [EdgeInsets] / CSS padding.
class EdgeInsets {
  final double left;
  final double top;
  final double right;
  final double bottom;
  const EdgeInsets.fromLTRB(this.left, this.top, this.right, this.bottom);
  const EdgeInsets.all(double v) : left = v, top = v, right = v, bottom = v;
  const EdgeInsets.only({this.left = 0, this.top = 0, this.right = 0, this.bottom = 0});
  const EdgeInsets.symmetric({double horizontal = 0, double vertical = 0})
      : left = horizontal,
        right = horizontal,
        top = vertical,
        bottom = vertical;
  static const zero = EdgeInsets.only();
  double get horizontal => left + right;
  double get vertical => top + bottom;
  Size inflateSize(Size s) => Size(s.width + left + right, s.height + top + bottom);
  Size deflateSize(Size s) => Size(
        math.max(0, s.width - horizontal),
        math.max(0, s.height - vertical),
      );
}
