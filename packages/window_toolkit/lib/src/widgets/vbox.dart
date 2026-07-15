import '../painter/painter.dart';
import '../widget.dart';

/// Vertical stack of children (counterpart to [HBox]).
class VBox extends Widget {
  @override

  final List<Widget> children;
  int spacing;

  VBox({this.spacing = 0, List<Widget>? children})
      : children = children ?? [];

  @override
  void performLayout(int containerWidth) {
    width = containerWidth;
    var totalH = 0;
    var maxW = 0;
    for (var i = 0; i < children.length; i++) {
      children[i].performLayout(containerWidth);
      totalH += children[i].height;
      if (children[i].width > maxW) maxW = children[i].width;
      if (i > 0) totalH += spacing;
    }
    height = totalH;
    if (maxW > 0) width = maxW.clamp(0, containerWidth);
    // Set child positions so hit-test works without a prior draw.
    var cy = y;
    for (final child in children) {
      child.x = x;
      child.y = cy;
      cy += child.height + spacing;
    }
  }

  void layout(int containerWidth, int containerHeight) {
    width = containerWidth;
    if (containerHeight > 0) height = containerHeight;

    var cy = y;
    for (final child in children) {
      child.x = x;
      child.y = cy;
      child.width = width;
      cy += child.height + spacing;
    }
  }

  @override
  void measure(Painter painter) {
    var totalH = 0;
    var maxW = 0;
    for (var i = 0; i < children.length; i++) {
      children[i].measure(painter);
      totalH += children[i].height;
      if (children[i].width > maxW) maxW = children[i].width;
      if (i > 0) totalH += spacing;
    }
    width = maxW;
    height = totalH;
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
