import 'package:layout_engine/layout_engine.dart' as le;

import '../painter/painter.dart';
import '../widget.dart';

/// Wrap layout that flows children into multiple rows, backed by [le.RenderWrap].
class WrapLayout extends Widget {
  @override

  final List<Widget> children;
  int spacing;
  int runSpacing;
  final le.RenderWrap _renderWrap = le.RenderWrap();
  final List<_WrapChildBox> _renderChildren = [];

  WrapLayout({
    this.spacing = 0,
    this.runSpacing = 0,
    List<Widget>? children,
  }) : children = children ?? [];

  void _ensureRenderTree() {
    _renderWrap.children.clear();
    _renderChildren.clear();
    for (final child in children) {
      final r = _WrapChildBox(child);
      _renderChildren.add(r);
      _renderWrap.attach(r);
    }
  }

  @override
  void performLayout(int containerWidth) {
    _ensureRenderTree();
    _renderWrap.spacing = spacing.toDouble();
    _renderWrap.runSpacing = runSpacing.toDouble();
    for (final c in children) {
      c.parent = this;
    }

    for (final r in _renderChildren) {
      r.widget.performLayout(containerWidth);
      r.size = le.Size(r.widget.width.toDouble(), r.widget.height.toDouble());
    }

    _renderWrap.layout(le.BoxConstraints(
      maxWidth: containerWidth.toDouble(),
      maxHeight: double.infinity,
    ));

    width = _renderWrap.size.width.round();
    height = _renderWrap.size.height.round();

    for (var i = 0; i < _renderChildren.length; i++) {
      final r = _renderChildren[i];
      r.widget.x = x + r.offset.dx.round();
      r.widget.y = y + r.offset.dy.round();
    }
  }

  /// Legacy API. Prefer [performLayout].
  void layout(int containerWidth, int containerHeight) {
    performLayout(containerWidth);
    if (containerHeight > 0) height = containerHeight;
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
    if (_renderChildren.isEmpty && width > 0) {
      performLayout(width);
    }
    if (!super.hitTest(px, py)) return false;
    for (final child in children.reversed) {
      if (child.hitTest(px, py)) return true;
    }
    return false;
  }
}

class _WrapChildBox extends le.RenderBox {
  final Widget widget;
  _WrapChildBox(this.widget);

  @override
  void layout(le.BoxConstraints constraints) {
    final w = constraints.hasBoundedWidth ? constraints.maxWidth.round() : 0;
    widget.performLayout(w);
    size = le.Size(widget.width.toDouble(), widget.height.toDouble());
  }
}
