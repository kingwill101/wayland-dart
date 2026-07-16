import 'package:layout_engine/layout_engine.dart' as le;

import '../painter/painter.dart';
import '../widget.dart';
import '../font/font_database.dart';
import '../font/font.dart';

/// Vertical stack of children, backed by [le.RenderColumn] for layout.
class VBox extends Widget {
  @override

  final List<Widget> children;
  int spacing;
  final le.RenderColumn _renderColumn = le.RenderColumn();
  final List<_RenderWidgetBox> _renderChildren = [];

  VBox({this.spacing = 0, List<Widget>? children, WidgetKey? key})
      : assert(spacing >= 0, 'VBox spacing must be >= 0'),
        children = children ?? [],
        super(key: key);

  void _ensureRenderTree() {
    _renderColumn.children.clear();
    _renderChildren.clear();
    for (final child in children) {
      final r = _RenderWidgetBox(child);
      _renderChildren.add(r);
      _renderColumn.attach(r);
    }
  }

  @override
  void performLayout(int containerWidth) {
    assert(containerWidth >= 0, 'VBox.performLayout: containerWidth=$containerWidth must be >= 0');
    _ensureRenderTree();
    _renderColumn.gap = spacing.toDouble();

    // Measure children and set their sizes.
    for (final r in _renderChildren) {
      r.widget.performLayout(containerWidth);
    }

    _renderColumn.layout(le.BoxConstraints(
      maxWidth: containerWidth.toDouble(),
      maxHeight: double.infinity,
    ));

    width = _renderColumn.size.width.round();
    height = _renderColumn.size.height.round();

    // Apply computed offsets to children.
    for (var i = 0; i < _renderChildren.length; i++) {
      final r = _renderChildren[i];
      r.widget.x = x + r.offset.dx.round();
      r.widget.y = y + r.offset.dy.round();
      r.widget.width = r.size.width.round();
    }
  }

  void layout(int containerWidth, int containerHeight) {
    performLayout(containerWidth);
    if (containerHeight > 0) height = containerHeight;
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

/// Adapter: wraps a [Widget] as a [le.RenderBox] for layout.
class _RenderWidgetBox extends le.RenderBox {
  final Widget widget;
  _RenderWidgetBox(this.widget);

  @override
  void layout(le.BoxConstraints constraints) {
    final childWidth = widget.width > 0
        ? widget.width
        : (constraints.hasBoundedWidth ? constraints.maxWidth.round() : widget.width);
    widget.performLayout(childWidth);
    size = le.Size(widget.width.toDouble(), widget.height.toDouble());
  }
}
