import 'package:layout_engine/layout_engine.dart' as le;

import '../painter/painter.dart';
import '../widget.dart';

/// Horizontal row of children, backed by [le.RenderRow] for layout.
class HBox extends Widget {
  @override
  final List<Widget> children;
  int spacing;
  final le.RenderRow _renderRow = le.RenderRow();
  final List<_RenderWidgetBox> _renderChildren = [];

  HBox({this.spacing = 0, List<Widget>? children, super.key})
    : assert(spacing >= 0, 'HBox spacing must be >= 0'),
      children = children ?? [];

  void _ensureRenderTree() {
    _renderRow.children.clear();
    _renderChildren.clear();
    for (final child in children) {
      final r = _RenderWidgetBox(child);
      _renderChildren.add(r);
      _renderRow.attach(r);
    }
  }

  @override
  void performLayout(int containerWidth) {
    _ensureRenderTree();
    _renderRow.gap = spacing.toDouble();
    for (final c in children) {
      c.parent = this;
    }

    for (final r in _renderChildren) {
      r.widget.performLayout(
        r.widget.width > 0 ? r.widget.width : containerWidth,
      );
    }

    _renderRow.layout(
      le.BoxConstraints(
        maxWidth: containerWidth.toDouble(),
        maxHeight: double.infinity,
      ),
    );

    width = containerWidth > 0 ? containerWidth : _renderRow.size.width.round();
    height = _renderRow.size.height.round();

    for (var i = 0; i < _renderChildren.length; i++) {
      final r = _renderChildren[i];
      r.widget.x = x + r.offset.dx.round();
      r.widget.y = y + r.offset.dy.round();
      r.widget.height = r.size.height.round();
    }
  }

  void layout(int containerWidth, int containerHeight) {
    performLayout(containerWidth);
    if (containerHeight > 0) height = containerHeight;
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
    // Always re-layout at draw (see VBox.draw): nested children are laid out
    // against a stale parent offset; re-applying at draw composes correctly.
    if (width > 0) performLayout(width);
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

/// Adapter: wraps a [Widget] as a [le.RenderBox] for layout.
class _RenderWidgetBox extends le.RenderBox {
  final Widget widget;
  _RenderWidgetBox(this.widget);

  @override
  void layout(le.BoxConstraints constraints) {
    // Use the child's intrinsic width first; fall back to constraints.
    final childWidth = widget.width > 0
        ? widget.width
        : (constraints.hasBoundedWidth
              ? constraints.maxWidth.round()
              : widget.width);
    widget.performLayout(childWidth);
    size = le.Size(widget.width.toDouble(), widget.height.toDouble());
  }
}
