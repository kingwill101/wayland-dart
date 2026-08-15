import 'package:layout_engine/layout_engine.dart' as le;

import '../painter/painter.dart';
import '../widget.dart';

/// How a [Positioned] child is placed inside a [Stack].
class Positioned extends Widget {
  @override
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
  }) : fixedWidth = width,
       fixedHeight = height;

  @override
  List<Widget> get children => [child];

  @override
  void measure(Painter painter) {
    child.measure(painter);
    width = fixedWidth ?? child.width;
    height = fixedHeight ?? child.height;
  }

  @override
  void performLayout(int containerWidth) {
    final stretchesHorizontally = left != null && right != null;
    final availableWidth = stretchesHorizontally
        ? (containerWidth - left! - right!).clamp(0, containerWidth)
        : (child.width > 0 ? child.width : 0);
    child.performLayout(availableWidth);
    width =
        fixedWidth ?? (stretchesHorizontally ? availableWidth : child.width);
    height = fixedHeight ?? child.height;
    child.parent = this;
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

/// Layers children. Backed by [le.RenderStack] for layout.
class Stack extends Widget {
  @override
  final List<Widget> children;
  final le.RenderStack _renderStack = le.RenderStack();
  final List<_StackChildBox> _renderChildren = [];

  Stack({List<Widget>? children, bool fitExpand = true})
    : children = children ?? [] {
    _renderStack.fit = fitExpand ? le.StackFit.expand : le.StackFit.loose;
  }

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

  void _ensureRenderTree() {
    _renderStack.children.clear();
    _renderChildren.clear();
    for (final child in children) {
      final r = _StackChildBox(child);
      _renderChildren.add(r);
      _renderStack.attach(r);
    }
  }

  @override
  void performLayout(int containerWidth) {
    _ensureRenderTree();
    for (final r in _renderChildren) {
      r.widget.performLayout(
        r.widget.width > 0 ? r.widget.width : containerWidth,
      );
      r.size = le.Size(r.widget.width.toDouble(), r.widget.height.toDouble());
    }
    _renderStack.layout(
      le.BoxConstraints(
        maxWidth: containerWidth.toDouble(),
        maxHeight: double.infinity,
      ),
    );
    width = _renderStack.size.width.round();
    height = _renderStack.size.height.round();

    for (var i = 0; i < _renderChildren.length; i++) {
      final r = _renderChildren[i];
      final w = r.widget;
      w.x = x + r.offset.dx.round();
      w.y = y + r.offset.dy.round();
      w.width = r.size.width.round();
      w.height = r.size.height.round();
    }
  }

  @override
  void draw(Painter canvas) {
    if (_renderChildren.isEmpty && width > 0) {
      performLayout(width);
    }
    for (final child in children) {
      child.draw(canvas);
    }
  }

  @override
  bool hitTest(int px, int py) {
    if (!super.hitTest(px, py)) return false;
    for (final child in children.reversed) {
      if (child.hitTest(px, py)) return true;
    }
    return false;
  }
}

class _StackChildBox extends le.RenderBox {
  final Widget widget;
  _StackChildBox(this.widget) {
    if (widget is Positioned) {
      final p = widget as Positioned;
      parentData = le.StackParentData(
        left: p.left?.toDouble(),
        right: p.right?.toDouble(),
        top: p.top?.toDouble(),
        bottom: p.bottom?.toDouble(),
        width: p.fixedWidth?.toDouble(),
        height: p.fixedHeight?.toDouble(),
      );
    }
  }

  @override
  void layout(le.BoxConstraints constraints) {
    final positioned = widget is Positioned ? widget as Positioned : null;
    final stretchesHorizontally =
        positioned?.left != null && positioned?.right != null;
    final childW = stretchesHorizontally && constraints.hasBoundedWidth
        ? constraints.maxWidth.round()
        : (widget.width > 0
              ? widget.width
              : (constraints.hasBoundedWidth
                    ? constraints.maxWidth.round()
                    : widget.width));
    widget.performLayout(childW);
    size = le.Size(widget.width.toDouble(), widget.height.toDouble());
  }
}
