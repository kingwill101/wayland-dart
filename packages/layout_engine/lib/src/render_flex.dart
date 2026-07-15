/// Flex layout render objects: [RenderRow] and [RenderColumn].
library;

import 'dart:math' as math;

import 'geometry.dart';
import 'render_object.dart';
import 'text_measure.dart';

/// Main-axis alignment for flex layouts.
enum MainAxisAlignment { start, end, center, spaceBetween, spaceAround, spaceEvenly }

/// Cross-axis alignment for flex layouts.
enum CrossAxisAlignment { start, end, center, stretch }

/// How a flex child should尺寸itself.
enum FlexFit { tight, loose }

/// How much space the flex layout consumes on its main axis.
enum MainAxisSize { min, max }

/// Base class for row and column render objects.
abstract class RenderFlex extends RenderBox {
  double gap;
  MainAxisAlignment mainAxisAlignment;
  CrossAxisAlignment crossAxisAlignment;
  MainAxisSize mainAxisSize;

  RenderFlex({
    this.gap = 0.0,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.mainAxisSize = MainAxisSize.min,
  });

  bool get isRow;

  /// Compute sizes for each child given available space.
  @override
  void layout(BoxConstraints constraints) {
    final measure = TextMeasureScope.current;

    if (isRow) {
      _layoutRow(constraints, measure);
    } else {
      _layoutColumn(constraints, measure);
    }
  }

  void _layoutRow(BoxConstraints constraints, TextMeasure measure) {
    // Phase 1: measure non-flexible children.
    var totalFixed = gap * (children.length - 1).clamp(0, children.length);
    var flexCount = 0;
    final childData = <_ChildData>[];

    for (final child in children) {
      final flex = _flexOf(child);
      if (flex > 0) {
        flexCount++;
        childData.add(_ChildData(child: child, flex: flex, width: null));
      } else {
        child.layout(constraints.loosen());
        totalFixed += child.size.width;
        childData.add(_ChildData(child: child, flex: 0, width: child.size.width));
      }
    }

    // Phase 2: distribute remaining space to flex children.
    final availableWidth = constraints.maxWidth - totalFixed;
    if (flexCount > 0 && availableWidth > 0) {
      final flexUnit = availableWidth / flexCount;
      for (final data in childData) {
        if (data.flex > 0) {
          final w = flexUnit * data.flex;
          data.child.layout(constraints.tighten(width: w));
          data.width = data.child.size.width;
        }
      }
    }

    // Phase 3: compute total size.
    var totalW = 0.0;
    var maxH = 0.0;
    for (final data in childData) {
      totalW += data.width ?? 0;
      if (data.child.size.height > maxH) maxH = data.child.size.height;
    }
    totalW += gap * (children.length - 1).clamp(0, children.length);

    if (mainAxisSize == MainAxisSize.max) {
      totalW = constraints.maxWidth;
    }
    size = Size(totalW, maxH.clamp(constraints.minHeight, constraints.maxHeight));

    // Phase 4: position children.
    var dx = _mainAxisStart(totalW);
    if (isRow) {
      for (final data in childData) {
        data.child.offset = Offset(dx, _crossAxisOffset(data.child.size.height));
        dx += (data.width ?? 0) + gap;
      }
    }
  }

  void _layoutColumn(BoxConstraints constraints, TextMeasure measure) {
    var totalFixed = gap * (children.length - 1).clamp(0, children.length);
    var flexCount = 0;
    final childData = <_ChildData>[];

    for (final child in children) {
      final flex = _flexOf(child);
      if (flex > 0) {
        flexCount++;
        childData.add(_ChildData(child: child, flex: flex, height: null));
      } else {
        child.layout(constraints.loosen());
        totalFixed += child.size.height;
        childData.add(_ChildData(child: child, flex: 0, height: child.size.height));
      }
    }

    final availableHeight = constraints.maxHeight - totalFixed;
    if (flexCount > 0 && availableHeight > 0) {
      final flexUnit = availableHeight / flexCount;
      for (final data in childData) {
        if (data.flex > 0) {
          final h = flexUnit * data.flex;
          data.child.layout(constraints.tighten(height: h));
          data.height = data.child.size.height;
        }
      }
    }

    var totalH = 0.0;
    var maxW = 0.0;
    for (final data in childData) {
      totalH += data.height ?? 0;
      if (data.child.size.width > maxW) maxW = data.child.size.width;
    }
    totalH += gap * (children.length - 1).clamp(0, children.length);

    if (mainAxisSize == MainAxisSize.max) {
      totalH = constraints.maxHeight;
    }
    size = Size(maxW.clamp(constraints.minWidth, constraints.maxWidth), totalH);

    var dy = _mainAxisStart(totalH);
    for (final data in childData) {
      data.child.offset = Offset(_crossAxisOffset(data.child.size.width), dy);
      dy += (data.height ?? 0) + gap;
    }
  }

  double _mainAxisStart(double total) {
    final available = isRow
        ? constraints.maxWidth
        : constraints.maxHeight;
    final remaining = available - total;
    if (remaining <= 0) return 0;
    switch (mainAxisAlignment) {
      case MainAxisAlignment.start:
        return 0;
      case MainAxisAlignment.end:
        return remaining;
      case MainAxisAlignment.center:
        return remaining / 2;
      case MainAxisAlignment.spaceBetween:
        return 0; // handled during positioning
      case MainAxisAlignment.spaceAround:
        return remaining / (children.length * 2);
      case MainAxisAlignment.spaceEvenly:
        return remaining / (children.length + 1);
    }
  }

  double _crossAxisOffset(double childSize) {
    final available = isRow ? constraints.maxHeight : constraints.maxWidth;
    final remaining = available - childSize;
    if (remaining <= 0) return 0;
    switch (crossAxisAlignment) {
      case CrossAxisAlignment.start:
        return 0;
      case CrossAxisAlignment.center:
        return remaining / 2;
      case CrossAxisAlignment.end:
        return remaining;
      case CrossAxisAlignment.stretch:
        return 0;
    }
  }

  int _flexOf(RenderObject child) {
    // Simple: all children are inflexible by default.
    // Callers can set child data to indicate flex.
    return 0;
  }
}

class _ChildData {
  final RenderObject child;
  final int flex;
  double? width;
  double? height;
  _ChildData({required this.child, this.flex = 0, this.width, this.height});
}

/// Horizontal flex layout (left-to-right).
class RenderRow extends RenderFlex {
  RenderRow({
    super.gap,
    super.mainAxisAlignment,
    super.crossAxisAlignment,
    super.mainAxisSize,
  });

  @override
  bool get isRow => true;
}

/// Vertical flex layout (top-to-bottom).
class RenderColumn extends RenderFlex {
  RenderColumn({
    super.gap,
    super.mainAxisAlignment,
    super.crossAxisAlignment,
    super.mainAxisSize,
  });

  @override
  bool get isRow => false;
}
