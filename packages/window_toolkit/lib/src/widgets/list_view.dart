import 'package:layout_engine/layout_engine.dart' as le;

import '../painter/painter.dart';
import '../widget.dart';
import 'scroll_area.dart';

/// A vertical scrolling list of children.
///
/// Wraps [ScrollArea] + a vertical list layout backed by [le.RenderList].
/// Items are laid out sequentially and the viewport scrolls when content
/// overflows.
///
/// ```dart
/// ListView(
///   spacing: 4,
///   children: [
///     Button('Item 1'),
///     Button('Item 2'),
///     Button('Item 3'),
///   ],
/// )
/// ```
class ListView extends Widget {
  final List<Widget> listChildren;
  final int spacing;
  late final ScrollArea _scrollArea;
  late final _ListViewContent _content;

  @override
  List<Widget> get children => listChildren;

  ListView({
    required List<Widget> children,
    this.spacing = 0,
    int scrollbarWidth = 6,
    bool showScrollbar = true,
  }) : listChildren = children {
    _content = _ListViewContent(children: children, spacing: spacing);
    _scrollArea = ScrollArea(
      child: _content,
      scrollbarWidth: scrollbarWidth,
      showVertical: showScrollbar,
    );
  }

  @override
  void draw(Painter canvas) {
    _scrollArea
      ..x = x
      ..y = y
      ..width = width
      ..height = height;
    _scrollArea.draw(canvas);
  }

  @override
  void performLayout(int containerWidth) {
    width = containerWidth;
    _content.performLayout(containerWidth);
    height = _content.height;
    _scrollArea.x = x;
    _scrollArea.y = y;
    _scrollArea.width = width;
    _scrollArea.height = height;
    _scrollArea.performLayout(width);
  }

  @override
  bool hitTest(int px, int py) {
    _scrollArea.x = x;
    _scrollArea.y = y;
    _scrollArea.width = width;
    _scrollArea.height = height;
    return _scrollArea.hitTest(px, py);
  }
}

/// Internal content widget that lays out children vertically.
class _ListViewContent extends Widget {
  final List<Widget> children;
  final int spacing;
  final le.RenderList _renderList = le.RenderList();
  final List<_ListChildBox> _renderChildren = [];

  _ListViewContent({required this.children, this.spacing = 0});

  void _ensureRenderTree() {
    _renderList.children.clear();
    _renderChildren.clear();
    for (final child in children) {
      final r = _ListChildBox(child);
      _renderChildren.add(r);
      _renderList.attach(r);
    }
  }

  @override
  void draw(Painter canvas) {
    if (_renderChildren.isEmpty) _ensureRenderTree();
    for (final child in children) {
      child.x = x;
      child.y = y;
      child.draw(canvas);
    }
  }

  @override
  void performLayout(int containerWidth) {
    _ensureRenderTree();
    _renderList.gap = spacing.toDouble();
    for (final r in _renderChildren) {
      r.widget.width = containerWidth;
      r.widget.performLayout(containerWidth);
      r.size = le.Size(r.widget.width.toDouble(), r.widget.height.toDouble());
    }
    _renderList.layout(le.BoxConstraints(
      maxWidth: containerWidth.toDouble(),
      maxHeight: double.infinity,
    ));
    width = _renderList.size.width.round();
    height = _renderList.size.height.round();
    for (var i = 0; i < _renderChildren.length; i++) {
      final r = _renderChildren[i];
      r.widget.x = x + r.offset.dx.round();
      r.widget.y = y + r.offset.dy.round();
    }
  }

  @override
  bool hitTest(int px, int py) {
    for (final child in children.reversed) {
      if (child.hitTest(px, py)) return true;
    }
    return false;
  }
}

class _ListChildBox extends le.RenderBox {
  final Widget widget;
  _ListChildBox(this.widget);

  @override
  void layout(le.BoxConstraints constraints) {
    widget.performLayout(constraints.maxWidth.round());
    size = le.Size(widget.width.toDouble(), widget.height.toDouble());
  }
}
