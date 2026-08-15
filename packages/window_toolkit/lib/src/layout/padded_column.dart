/// Shared layout: [RenderPadding] → stretch [RenderColumn] of widget children.
///
/// Used by Card, GroupBox, and similar chrome containers so padding + vertical
/// stacking live in layout_engine rather than hand-rolled y-offsets.
library;

import 'package:layout_engine/layout_engine.dart' as le;

import '../widget.dart';
import 'render_widget_box.dart';

/// Lays out [children] in a padded, cross-axis-stretched column.
class PaddedColumnLayout {
  final le.RenderPadding padding = le.RenderPadding();
  final le.RenderColumn column = le.RenderColumn();
  final List<RenderWidgetBox> boxes = [];

  PaddedColumnLayout() {
    column.crossAxisAlignment = le.CrossAxisAlignment.stretch;
    padding.attach(column);
  }

  /// Run layout. Returns the outer size (padding + column).
  le.Size layout({
    required List<Widget> children,
    required int containerWidth,
    required le.EdgeInsets insets,
    double gap = 0,
  }) {
    column.gap = gap;
    column.children.clear();
    boxes.clear();
    for (final child in children) {
      final box = RenderWidgetBox(child);
      boxes.add(box);
      column.attach(box);
    }
    // Re-attach column if padding lost it (children.clear on column is fine).
    if (padding.children.isEmpty) {
      padding.attach(column);
    }

    padding.padding = insets;
    padding.layout(
      le.BoxConstraints(
        minWidth: containerWidth.toDouble(),
        maxWidth: containerWidth.toDouble(),
        maxHeight: double.infinity,
      ),
    );
    return padding.size;
  }

  /// Map laid-out boxes to absolute widget coordinates.
  ///
  /// [RenderPadding] places the column at [EdgeInsets] inset; each box offset
  /// is relative to the column — do not add padding again.
  void applyAbsolute({required int originX, required int originY}) {
    for (final box in boxes) {
      final w = box.widget;
      if (w == null) continue;
      final dx = column.offset.dx + box.offset.dx;
      final dy = column.offset.dy + box.offset.dy;
      w
        ..x = originX + dx.round()
        ..y = originY + dy.round()
        ..width = box.size.width.round()
        ..height = box.size.height.round();
    }
  }
}
