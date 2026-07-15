import '../painter/painter.dart';
import '../widget.dart';

class Padding extends Widget {
  @override
  @override
  List<Widget> get children => [child];

  Widget child;
  int left;
  int top;
  int right;
  int bottom;

  Padding({
    required this.child,
    this.left = 0,
    this.top = 0,
    this.right = 0,
    this.bottom = 0,
    int? all,
  })  : assert(left >= 0 && top >= 0 && right >= 0 && bottom >= 0,
            'Padding values must be >= 0') {
    if (all != null) {
      left = all;
      top = all;
      right = all;
      bottom = all;
    }
  }

  @override
  void performLayout(int containerWidth) {
    width = containerWidth;
    child.performLayout((width - left - right).clamp(0, width).toInt());
    height = top + child.height + bottom;
    child.x = x + left;
    child.y = y + top;
    child.width = (width - left - right).clamp(0, width).toInt();
  }

  void layout(int containerWidth, int containerHeight) {
    width = containerWidth;
    height = containerHeight;

    child.x = x + left;
    child.y = y + top;
    child.width = (width - left - right).clamp(0, width).toInt();
    child.height = (height - top - bottom).clamp(0, height).toInt();
  }

  @override
  void draw(Painter canvas) {
    layout(width, height);
    child.draw(canvas);
  }

  @override
  bool hitTest(int px, int py) {
    layout(width, height);
    if (!super.hitTest(px, py)) return false;
    return child.hitTest(px, py);
  }
}
