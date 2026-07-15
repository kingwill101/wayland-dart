/// Wrap layout: [RenderWrap] flows children into multiple rows/columns.
///
/// Ported from artisanal (RenderWrap), stripped of UV rendering.
library;

import 'dart:math' as math;

import 'geometry.dart';
import 'render_object.dart';

/// Direction for wrap layout.
enum Axis { horizontal, vertical }

/// Alignment along the main axis within a wrap run.
enum WrapAlignment { start, end, center, spaceBetween, spaceAround, spaceEvenly }

/// Alignment along the cross axis.
enum WrapCrossAlignment { start, end, center }

/// A single run (row/column) of wrapped children.
class _WrapRun {
  final List<_WrapItem> items;
  final int main;
  final int cross;
  _WrapRun(this.items, this.main, this.cross);
}

class _WrapItem {
  final RenderObject child;
  final int main;
  final int cross;
  _WrapItem(this.child, this.main, this.cross);
}

class _WrapSpacingData {
  final double leading;
  final List<double> between;
  _WrapSpacingData(this.leading, this.between);
}

/// Render object that wraps children into multiple rows (horizontal) or
/// columns (vertical) when they exceed the available space.
class RenderWrap extends RenderBox {
  Axis direction;
  WrapAlignment alignment;
  WrapCrossAlignment crossAxisAlignment;
  double spacing;
  double runSpacing;

  List<_WrapRun> _runs = const [];

  RenderWrap({
    this.direction = Axis.horizontal,
    this.alignment = WrapAlignment.start,
    this.crossAxisAlignment = WrapCrossAlignment.start,
    this.spacing = 0,
    this.runSpacing = 0,
  })  : assert(spacing >= 0, 'RenderWrap spacing must be >= 0'),
        assert(runSpacing >= 0, 'RenderWrap runSpacing must be >= 0');

  bool get _isHorizontal => direction == Axis.horizontal;

  @override
  void layout(BoxConstraints constraints) {
    _runs = _computeRuns(constraints);

    if (_runs.isEmpty) {
      size = constraints.constrain(Size.zero);
      return;
    }

    final contentMain = _runs.map((r) => r.main).reduce(math.max);
    final contentCross =
        _runs.fold<double>(0, (sum, run) => sum + run.cross) +
        runSpacing * math.max(0, _runs.length - 1);

    final w = _isHorizontal ? contentMain.toDouble() : contentCross.toDouble();
    final h = _isHorizontal ? contentCross.toDouble() : contentMain.toDouble();
    size = constraints.constrain(Size(w, h));

    // Position children.
    _positionChildren(constraints);
  }

  void _positionChildren(BoxConstraints constraints) {
    final totalW = size.width;
    final totalH = size.height;
    var crossOffset = 0.0;

    for (final run in _runs) {
      final availableMain = _isHorizontal ? totalW : totalH;
      final extraMain = availableMain - run.main;
      final spacingData = _computeSpacing(
        run.items.length, spacing, math.max(0, extraMain), alignment,
      );

      var mainOffset = spacingData.leading.toDouble();
      for (var i = 0; i < run.items.length; i++) {
        final item = run.items[i];
        final crossDelta = _crossOffset(run.cross.toDouble(), item.cross.toDouble());
        final dx = _isHorizontal ? mainOffset : crossOffset + crossDelta;
        final dy = _isHorizontal ? crossOffset + crossDelta : mainOffset;
        item.child.offset = Offset(dx, dy);
        mainOffset += item.main + (i < spacingData.between.length ? spacingData.between[i] : 0);
      }
      crossOffset += run.cross + runSpacing;
    }
  }

  List<_WrapRun> _computeRuns(BoxConstraints constraints) {
    if (children.isEmpty) return [];

    final runs = <_WrapRun>[];
    final maxMain = _isHorizontal
        ? (constraints.hasBoundedWidth ? constraints.maxWidth : null)
        : (constraints.hasBoundedHeight ? constraints.maxHeight : null);

    // Measure all children.
    final items = <_WrapItem>[];
    for (final child in children) {
      child.layout(constraints.loosen());
      final main = _isHorizontal ? child.size.width : child.size.height;
      final cross = _isHorizontal ? child.size.height : child.size.width;
      items.add(_WrapItem(child, main.round(), cross.round()));
    }

    if (maxMain == null || maxMain <= 0) {
      // No wrapping constraint — single run.
      final totalMain = items.fold<double>(0, (s, i) => s + i.main) +
          spacing * math.max(0, items.length - 1);
      final maxCross = items.fold<int>(0, (s, i) => s > i.cross ? s : i.cross);
      return [_WrapRun(items, totalMain.round(), maxCross)];
    }

    // Wrap into runs.
    var runItems = <_WrapItem>[];
    var runMain = 0.0;
    for (final item in items) {
      if (runItems.isNotEmpty && runMain + spacing + item.main > maxMain) {
        final maxCross = runItems.fold<int>(0, (s, i) => s > i.cross ? s : i.cross);
        runs.add(_WrapRun(List.from(runItems), runMain.round(), maxCross));
        runItems = [];
        runMain = 0;
      }
      runItems.add(item);
      runMain += (runItems.length > 1 ? spacing : 0) + item.main;
    }
    if (runItems.isNotEmpty) {
      final maxCross = runItems.fold<int>(0, (s, i) => s > i.cross ? s : i.cross);
      runs.add(_WrapRun(runItems, runMain.round(), maxCross));
    }

    return runs;
  }

  _WrapSpacingData _computeSpacing(
    int count, double gap, double extra, WrapAlignment align,
  ) {
    if (count <= 1) return _WrapSpacingData(0, []);
    switch (align) {
      case WrapAlignment.start:
        return _WrapSpacingData(0, List.filled(count - 1, gap));
      case WrapAlignment.end:
        return _WrapSpacingData(extra, List.filled(count - 1, gap));
      case WrapAlignment.center:
        return _WrapSpacingData(extra / 2, List.filled(count - 1, gap));
      case WrapAlignment.spaceBetween:
        final perGap = extra / (count - 1);
        return _WrapSpacingData(0, List.filled(count - 1, perGap));
      case WrapAlignment.spaceAround:
        final perGap = extra / count;
        return _WrapSpacingData(perGap, List.filled(count - 1, perGap * 2));
      case WrapAlignment.spaceEvenly:
        final perGap = extra / (count + 1);
        return _WrapSpacingData(perGap, List.filled(count - 1, perGap));
    }
  }

  double _crossOffset(double runCross, double childCross) {
    final remaining = runCross - childCross;
    if (remaining <= 0) return 0;
    switch (crossAxisAlignment) {
      case WrapCrossAlignment.start:
        return 0;
      case WrapCrossAlignment.center:
        return remaining / 2;
      case WrapCrossAlignment.end:
        return remaining;
    }
  }
}
