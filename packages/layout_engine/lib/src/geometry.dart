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

  static const tight = BoxConstraints();

  @pragma('vm:prefer-inline')
  bool get hasBoundedWidth => maxWidth < double.infinity;

  @pragma('vm:prefer-inline')
  bool get hasBoundedHeight => maxHeight < double.infinity;

  @pragma('vm:prefer-inline')
  bool get isTight => minWidth == maxWidth && minHeight == maxHeight;

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
