import '../painter/painter.dart';
import '../widget.dart';

class VBoxLayout extends Widget {
  @override

  final List<Widget> children;
  int spacing;

  VBoxLayout({this.spacing = 0, List<Widget>? children})
      : children = children ?? [];

  @override
  void performLayout(int containerWidth) {
    width = containerWidth;
    for (final c in children) {
      c.parent = this;
    }
    var totalH = 0;
    for (final child in children) {
      child.performLayout(width);
      totalH += child.height + spacing;
    }
    if (children.isNotEmpty) totalH -= spacing;
    height = totalH;
  }

  void layout() {
    int cy = y;
    for (final child in children) {
      child.x = x;
      child.y = cy;
      child.width = width;
      cy += child.height + spacing;
    }
    if (children.isNotEmpty) {
      height = cy - spacing - y;
    }
  }

  @override
  void draw(Painter canvas) {
    performLayout(width);
    layout();
    for (final child in children) {
      child.draw(canvas);
    }
  }

  @override
  bool hitTest(int px, int py) {
    performLayout(width);
    layout();
    if (!super.hitTest(px, py)) return false;
    for (final child in children.reversed) {
      if (child.hitTest(px, py)) return true;
    }
    return false;
  }
}
