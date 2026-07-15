import '../painter/painter.dart';
import '../widget.dart';

/// Centers [child] within the available size.
class Center extends Widget {
  @override
  @override
  List<Widget> get children => [child];

  final Widget child;

  Center({required this.child});

  @override
  void measure(Painter painter) {
    child.measure(painter);
    // Keep parent size if already set; otherwise hug child.
    if (width <= 0) width = child.width;
    if (height <= 0) height = child.height;
  }

  @override
  void performLayout(int containerWidth) {
    width = containerWidth;
    child.performLayout(child.width > 0 ? child.width : containerWidth);
    if (height <= 0) height = child.height;
  }

  @override
  void draw(Painter canvas) {
    child.x = x + (width - child.width) ~/ 2;
    child.y = y + (height - child.height) ~/ 2;
    child.draw(canvas);
  }

  @override
  bool hitTest(int px, int py) {
    if (!super.hitTest(px, py)) return false;
    child.x = x + (width - child.width) ~/ 2;
    child.y = y + (height - child.height) ~/ 2;
    return child.hitTest(px, py) || true;
  }
}
