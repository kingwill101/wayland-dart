/// A vertical scrolling list with key-based reconciliation.
///
/// When children have [WidgetKey]s, [ListView] preserves the state of
/// existing items across insert, remove, and reorder operations.
///
/// ```dart
/// ListView(
///   spacing: 4,
///   children: [
///     Button('Item 1', key: const WidgetKey('a')),
///     Button('Item 2', key: const WidgetKey('b')),
///     Button('Item 3', key: const WidgetKey('c')),
///   ],
/// )
/// ```
library;
import 'package:layout_engine/layout_engine.dart' as le;

import '../painter/painter.dart';
import '../widget.dart';
import 'scroll_area.dart';

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
    _scrollArea..x = x..y = y..width = width..height = height;
    _scrollArea.draw(canvas);
  }

  @override
  void performLayout(int containerWidth) {
    width = containerWidth;
    _content.performLayout(containerWidth);
    height = _content.height;
    _scrollArea..x = x..y = y..width = width..height = height;
    _scrollArea.performLayout(width);
  }

  @override
  bool hitTest(int px, int py) {
    _scrollArea..x = x..y = y..width = width..height = height;
    return _scrollArea.hitTest(px, py);
  }
}

class _ListViewContent extends Widget {
  @override
  final List<Widget> children;
  final int spacing;
  final le.RenderList _renderList = le.RenderList();
  final List<_ListChildBox> _renderChildren = [];

  _ListViewContent({required this.children, this.spacing = 0});

  void _ensureRenderTree() {
    _renderList.children.clear();
    if (_renderChildren.isEmpty) {
      for (final child in children) {
        _renderChildren.add(_ListChildBox(child));
        _renderList.attach(_renderChildren.last);
      }
    } else {
      _reconcile();
      for (final r in _renderChildren) {
        _renderList.attach(r);
      }
    }
  }

  void _reconcile() {
    final old = _renderChildren.toList();
    _renderChildren.clear();

    // Phase 1: walk from front matching by runtimeType + key.
    var i = 0;
    while (i < old.length && i < children.length && _canUpdate(old[i].widget, children[i])) {
      old[i].widget = children[i];
      _renderChildren.add(old[i]);
      i++;
    }
    if (i == old.length && i == children.length) return;

    // Phase 2: key remaining old items.
    final keyed = <Object, _ListChildBox>{};
    for (var j = old.length - 1; j >= i; j--) {
      if (old[j].widget.key != null) {
        keyed[old[j].widget.key!] = old[j];
      }
    }

    // Phase 3: match remaining new items by key.
    for (var j = i; j < children.length; j++) {
      final child = children[j];
      _ListChildBox? match;
      if (child.key != null && keyed.containsKey(child.key)) {
        match = keyed.remove(child.key!)!;
      }
      if (match != null) {
        match.widget = child;
        _renderChildren.add(match);
      } else {
        _renderChildren.add(_ListChildBox(child));
      }
    }
  }

  bool _canUpdate(Widget a, Widget b) {
    if (a.runtimeType != b.runtimeType) return false;
    if (a.key == null && b.key == null) return true;
    if (a.key == null || b.key == null) return false;
    return a.key == b.key;
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
  Widget widget;
  _ListChildBox(this.widget);

  @override
  void layout(le.BoxConstraints constraints) {
    widget.performLayout(constraints.maxWidth.round());
    size = le.Size(widget.width.toDouble(), widget.height.toDouble());
  }
}
