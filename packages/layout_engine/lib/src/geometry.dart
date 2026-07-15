/// Geometry primitives for widget layout.
library;

import 'dart:math' as math;

/// An offset in layout units.
class Offset {
  final double dx;
  final double dy;
  const Offset(this.dx, this.dy);
  static const zero = Offset(0, 0);

  Offset operator +(Offset other) => Offset(dx + other.dx, dy + other.dy);
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

  Size operator +(Size other) => Size(width + other.width, height + other.height);
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
  Rect.fromOffsetAndSize(Offset offset, Size size)
      : left = offset.dx,
        top = offset.dy,
        width = size.width,
        height = size.height;

  double get right => left + width;
  double get bottom => top + height;
  Offset get offset => Offset(left, top);
  Size get size => Size(width, height);
  Rect shift(double dx, double dy) =>
      Rect.fromLTWH(left + dx, top + dy, width, height);

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

  bool get hasBoundedWidth => maxWidth < double.infinity;
  bool get hasBoundedHeight => maxHeight < double.infinity;
  bool get isTight => minWidth == maxWidth && minHeight == maxHeight;

  /// Constrain [size] to fit within these constraints.
  Size constrain(Size size) {
    return Size(
      size.width < minWidth
          ? minWidth
          : size.width > maxWidth
              ? maxWidth
              : size.width,
      size.height < minHeight
          ? minHeight
          : size.height > maxHeight
              ? maxHeight
              : size.height,
    );
  }

  /// Tighten constraints to a specific size.
  BoxConstraints tighten({double? width, double? height}) {
    return BoxConstraints(
      minWidth: width ?? minWidth,
      maxWidth: width ?? maxWidth,
      minHeight: height ?? minHeight,
      maxHeight: height ?? maxHeight,
    );
  }

  /// Loosen constraints (set min to 0).
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
