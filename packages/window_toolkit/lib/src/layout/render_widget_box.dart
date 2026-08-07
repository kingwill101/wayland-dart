/// Shared adapter from window_toolkit [Widget] to layout_engine [RenderBox].
///
/// Centralizes constraint → [Widget.performLayout] mapping so containers cannot
/// "stick" to a previous frame's width when the parent offers a larger max.
library;

import 'package:layout_engine/layout_engine.dart' as le;

import '../widget.dart';

/// Adapts a [Widget] as a [le.RenderBox] for use inside layout_engine trees.
///
/// Contract:
/// - **Never** prefer a stale [Widget.width] over a larger bounded constraint.
/// - Tight width (`minWidth == maxWidth`) forces that width on the widget.
/// - Loose bounded width passes `maxWidth` so expanding containers fill space;
///   leaf widgets (Button, Label, …) must keep their intrinsic size inside
///   [Widget.performLayout] rather than always stretching.
/// - Unbounded width uses the widget's current/intrinsic width.
/// - Optional [flex] installs [le.FlexParentData] for [le.RenderFlex].
class RenderWidgetBox extends le.RenderBox {
  Widget? widget;
  int flex;

  RenderWidgetBox(this.widget, {this.flex = 0}) {
    _syncFlexParentData();
  }

  void _syncFlexParentData() {
    parentData = flex > 0 ? le.FlexParentData(flex: flex) : null;
  }

  /// Update flex factor (e.g. when rebuilding a Flex child list).
  void setFlex(int value) {
    if (flex == value) return;
    flex = value;
    _syncFlexParentData();
  }

  @override
  void layout(le.BoxConstraints constraints) {
    this.constraints = constraints;
    final w = widget;
    if (w == null) {
      size = constraints.constrain(le.Size.zero);
      return;
    }

    final layoutWidth = _layoutWidthFor(w, constraints);
    w.performLayout(layoutWidth);

    var reportedW = w.width.toDouble();
    var reportedH = w.height.toDouble();
    if (!reportedW.isFinite || reportedW < 0) reportedW = 0;
    if (!reportedH.isFinite || reportedH < 0) reportedH = 0;

    // Tight main/cross constraints force the widget size.
    if (constraints.hasBoundedWidth &&
        constraints.minWidth == constraints.maxWidth) {
      reportedW = constraints.maxWidth;
      w.width = reportedW.round();
    }
    if (constraints.hasBoundedHeight &&
        constraints.minHeight == constraints.maxHeight) {
      reportedH = constraints.maxHeight;
      w.height = reportedH.round();
    }

    size = constraints.constrain(le.Size(reportedW, reportedH));

    // Keep the widget in sync if constrain() changed the reported size.
    // Guard non-finite results (unbounded flex, etc.).
    if (size.width.isFinite && w.width.toDouble() != size.width) {
      w.width = size.width.round();
    }
    if (size.height.isFinite && w.height.toDouble() != size.height) {
      w.height = size.height.round();
    }
    if (!size.width.isFinite || !size.height.isFinite) {
      size = le.Size(
        size.width.isFinite ? size.width : reportedW,
        size.height.isFinite ? size.height : reportedH,
      );
    }
  }

  /// Resolve the width argument for [Widget.performLayout].
  ///
  /// Bounded constraints always win over a previous frame's width so that
  /// growing the parent (window resize, ScrollArea viewport) expands children.
  static int _layoutWidthFor(Widget w, le.BoxConstraints constraints) {
    if (constraints.hasBoundedWidth) {
      final max = constraints.maxWidth;
      if (max.isFinite) {
        return max.round().clamp(0, 1 << 30);
      }
    }
    // Unbounded: intrinsic / previously measured width.
    return w.width > 0 ? w.width : 0;
  }
}
