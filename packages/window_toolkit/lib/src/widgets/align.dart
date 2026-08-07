import '../painter/painter.dart';
import '../widget.dart';

class Align extends Widget {
  @override
  @override
  List<Widget> get children => [child];

  Widget child;
  HorizontalAlignment horizontalAlignment;
  VerticalAlignment verticalAlignment;

  Align({
    required this.child,
    this.horizontalAlignment = HorizontalAlignment.center,
    this.verticalAlignment = VerticalAlignment.center,
  });

  @override
  void performLayout(int containerWidth) {
    width = containerWidth;
    child.performLayout(width);
    height = child.height;
    _positionChild();
  }

  void _positionChild() {
    int cx = x;
    if (horizontalAlignment == HorizontalAlignment.center) {
      cx = x + (width - child.width) ~/ 2;
    } else if (horizontalAlignment == HorizontalAlignment.right) {
      cx = x + width - child.width;
    }

    int cy = y;
    if (verticalAlignment == VerticalAlignment.center) {
      cy = y + (height - child.height) ~/ 2;
    } else if (verticalAlignment == VerticalAlignment.bottom) {
      cy = y + height - child.height;
    }

    child.x = cx;
    child.y = cy;
  }

  @override
  void measure(Painter painter) {
    child.measure(painter);
    width = child.width;
    height = child.height;
  }

  void layout(int containerWidth, int containerHeight) {
    width = containerWidth;
    height = containerHeight;
    _positionChild();
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

enum HorizontalAlignment { left, center, right }

enum VerticalAlignment { top, center, bottom }
