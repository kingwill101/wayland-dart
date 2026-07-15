import '../painter/painter.dart';
import '../widget.dart';

class WrapLayout extends Widget {
  @override

  final List<Widget> children;
  int spacing;
  int runSpacing;

  WrapLayout({
    this.spacing = 0,
    this.runSpacing = 0,
    List<Widget>? children,
  }) : children = children ?? [];

  @override
  void performLayout(int containerWidth) {
    for (final child in children) {
      child.performLayout(child.width);
    }
    width = containerWidth;
    layout(width, 0);
  }

  int _intrinsicWidth() {
    if (children.isEmpty) return 0;
    var total = 0;
    for (final child in children) {
      total += child.width;
    }
    return total + (children.length - 1) * spacing;
  }

  void layout(int containerWidth, int containerHeight) {
    final effectiveWidth = containerWidth > 0 ? containerWidth : _intrinsicWidth();
    width = effectiveWidth;

    var cx = x;
    var cy = y;
    var lineHeight = 0;
    var usedHeight = 0;
    var lineStartX = x;

    for (final child in children) {
      final childWidth = child.width;
      final childHeight = child.height;

      final shouldWrap =
          cx > lineStartX && (cx + childWidth) > (x + effectiveWidth);
      if (shouldWrap) {
        cx = x;
        cy += lineHeight + runSpacing;
        usedHeight += lineHeight + runSpacing;
        lineHeight = 0;
      }

      child.x = cx;
      child.y = cy;
      cx += childWidth + spacing;
      if (childHeight > lineHeight) {
        lineHeight = childHeight;
      }
    }

    usedHeight += lineHeight;
    height = containerHeight > 0 ? containerHeight : usedHeight;
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
