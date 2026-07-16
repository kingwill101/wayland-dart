import '../painter/painter.dart';
import '../widget.dart';

/// Captures hover/click callbacks around [child] without changing layout.
class MouseRegion extends Widget {
  final Widget child;
  final VoidCallback? onEnter;
  final VoidCallback? onExit;
  final VoidCallback? onTap;

  bool _hovered = false;
  bool get isHovered => _hovered;

  MouseRegion({
    required this.child,
    this.onEnter,
    this.onExit,
    this.onTap,
  }) : assert(child != null, 'MouseRegion child must not be null') {
    onMouseEnter = () {
      setState(() => _hovered = true);
      onEnter?.call();
    };
    onMouseLeave = () {
      setState(() => _hovered = false);
      onExit?.call();
    };
    onClick = () { onTap?.call(); return true; };
  }

  @override
  void measure(Painter painter) {
    child.measure(painter);
    width = child.width;
    height = child.height;
  }

  @override
  void performLayout(int containerWidth) {
    child.performLayout(containerWidth);
    width = child.width;
    height = child.height;
  }

  void _sync() {
    child
      ..x = x
      ..y = y
      ..width = width
      ..height = height;
  }

  @override
  void draw(Painter canvas) {
    _sync();
    child.draw(canvas);
  }

  @override
  bool hitTest(int px, int py) {
    if (!super.hitTest(px, py)) return false;
    _sync();
    return true;
  }
}
