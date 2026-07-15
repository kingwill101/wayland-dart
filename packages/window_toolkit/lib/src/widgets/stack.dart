import '../painter/painter.dart';
import '../widget.dart';

/// How a [Positioned] child is placed inside a [Stack].
class Positioned extends Widget {
  final Widget child;
  final int? left;
  final int? top;
  final int? right;
  final int? bottom;
  final int? fixedWidth;
  final int? fixedHeight;

  Positioned({
    required this.child,
    this.left,
    this.top,
    this.right,
    this.bottom,
    int? width,
    int? height,
  })  : fixedWidth = width,
        fixedHeight = height;

  @override
  void measure(Painter painter) {
    child.measure(painter);
    width = fixedWidth ?? child.width;
    height = fixedHeight ?? child.height;
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
    child
      ..x = x
      ..y = y
      ..width = width
      ..height = height;
    return child.hitTest(px, py);
  }
}

/// Layers children on top of each other; non-positioned children fill the stack.
class Stack extends Widget {
  final List<Widget> children;
  final bool fitExpand;

  Stack({List<Widget>? children, this.fitExpand = true})
      : children = children ?? [];

  @override
  void measure(Painter painter) {
    var maxW = 0;
    var maxH = 0;
    for (final child in children) {
      child.measure(painter);
      if (child.width > maxW) maxW = child.width;
      if (child.height > maxH) maxH = child.height;
    }
    width = maxW;
    height = maxH;
  }

  void _layoutChildren() {
    for (final child in children) {
      if (child is Positioned) {
        final w = child.fixedWidth ?? child.child.width;
        final h = child.fixedHeight ?? child.child.height;
        var cx = x;
        var cy = y;
        if (child.left != null) {
          cx = x + child.left!;
        } else if (child.right != null) {
          cx = x + width - child.right! - w;
        }
        if (child.top != null) {
          cy = y + child.top!;
        } else if (child.bottom != null) {
          cy = y + height - child.bottom! - h;
        }
        child.x = cx;
        child.y = cy;
        child.width = w;
        child.height = h;
      } else if (fitExpand) {
        child
          ..x = x
          ..y = y
          ..width = width
          ..height = height;
      } else {
        child
          ..x = x
          ..y = y;
      }
    }
  }

  @override
  void draw(Painter canvas) {
    _layoutChildren();
    for (final child in children) {
      child.draw(canvas);
    }
  }

  @override
  bool hitTest(int px, int py) {
    if (!super.hitTest(px, py)) return false;
    _layoutChildren();
    for (final child in children.reversed) {
      if (child.hitTest(px, py)) return true;
    }
    return false;
  }
}
