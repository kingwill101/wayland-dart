import '../painter/painter.dart';
import '../widget.dart';

class HBox extends Widget {
  @override

  final List<Widget> children;
  int spacing;

  HBox({this.spacing = 0, List<Widget>? children})
      : children = children ?? [];

  @override
  void performLayout(int containerWidth) {
    width = containerWidth;
    var maxHeight = 0;
    for (final child in children) {
      child.performLayout(child.width > 0 ? child.width : width ~/ children.length);
      if (child.height > maxHeight) maxHeight = child.height;
    }
    height = maxHeight;
  }

  void layout(int containerWidth, int containerHeight) {
    width = containerWidth;
    // Do not call [performLayout] here: the default implementation sets
    // `child.width = containerWidth`, which stretches intrinsic children
    // (e.g. bar ModuleWidgets) and creates huge gaps between icons.
    if (containerHeight > 0) height = containerHeight;

    int cx = x;
    for (final child in children) {
      child.x = cx;
      child.y = y;
      child.height = height;
      cx += child.width + spacing;
    }
  }

  @override
  void measure(Painter painter) {
    var totalW = 0;
    var maxH = 0;
    for (int i = 0; i < children.length; i++) {
      children[i].measure(painter);
      totalW += children[i].width;
      if (children[i].height > maxH) maxH = children[i].height;
      if (i > 0) totalW += spacing;
    }
    width = totalW;
    height = maxH;
  }

  @override
  void draw(Painter canvas) {
    layout(width, height);
    for (final child in children) {
      child.draw(canvas);
    }
  }

  @override
  bool hitTest(int px, int py) {
    layout(width, height);
    if (!super.hitTest(px, py)) return false;
    for (final child in children.reversed) {
      if (child.hitTest(px, py)) return true;
    }
    return false;
  }
}
