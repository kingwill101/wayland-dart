import '../painter/painter.dart';
import '../widget.dart';

/// Forces [child] (or empty space) to a fixed size.
class SizedBox extends Widget {
  final Widget? child;
  final int? fixedWidth;
  final int? fixedHeight;

  SizedBox({this.child, int? width, int? height})
      : fixedWidth = width,
        fixedHeight = height {
    if (width != null) this.width = width;
    if (height != null) this.height = height;
  }

  @override
  void measure(Painter painter) {
    child?.measure(painter);
    width = fixedWidth ?? child?.width ?? width;
    height = fixedHeight ?? child?.height ?? height;
  }

  @override
  void performLayout(int containerWidth) {
    width = fixedWidth ?? containerWidth;
    if (child != null) {
      child!.performLayout(width);
      height = fixedHeight ?? child!.height;
    } else {
      height = fixedHeight ?? height;
    }
  }

  @override
  void draw(Painter canvas) {
    if (child == null) return;
    child!
      ..x = x
      ..y = y
      ..width = width
      ..height = height;
    child!.draw(canvas);
  }

  @override
  bool hitTest(int px, int py) {
    if (!super.hitTest(px, py)) return false;
    if (child == null) return true;
    child!
      ..x = x
      ..y = y
      ..width = width
      ..height = height;
    return child!.hitTest(px, py);
  }
}

/// Clamps child size between min/max bounds.
class ConstrainedBox extends Widget {
  final Widget child;
  final int? minWidth;
  final int? maxWidth;
  final int? minHeight;
  final int? maxHeight;

  ConstrainedBox({
    required this.child,
    this.minWidth,
    this.maxWidth,
    this.minHeight,
    this.maxHeight,
  });

  int _clamp(int value, int? min, int? max) {
    var v = value;
    if (min != null && v < min) v = min;
    if (max != null && v > max) v = max;
    return v;
  }

  @override
  void measure(Painter painter) {
    child.measure(painter);
    width = _clamp(child.width, minWidth, maxWidth);
    height = _clamp(child.height, minHeight, maxHeight);
  }

  @override
  void draw(Painter canvas) {
    child
      ..x = x
      ..y = y
      ..width = width
      ..height = height;
    child.draw(canvas);
  }

  @override
  bool hitTest(int px, int py) {
    if (!super.hitTest(px, py)) return false;
    child
      ..x = x
      ..y = y
      ..width = width
      ..height = height;
    return child.hitTest(px, py);
  }
}
