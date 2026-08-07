import '../painter/painter.dart';
import '../widget.dart';

enum Axis { horizontal, vertical }

enum FlexFit { tight, loose }

enum MainAxisAlignment { start, center, end, spaceBetween, spaceAround, spaceEvenly }

enum CrossAxisAlignment { start, center, end, stretch }

class Flexible extends Widget {
  @override

  final Widget child;
  int flex;
  FlexFit fit;

  Flexible({required this.child, this.flex = 1, this.fit = FlexFit.loose});

  @override
  void performLayout(int containerWidth) {
    width = containerWidth;
    child.performLayout(containerWidth);
    height = child.height;
  }

  void _syncChildBounds() {
    child
      ..x = x
      ..y = y
      ..width = width
      ..height = height;
  }

  @override
  void draw(Painter canvas) {
    _syncChildBounds();
    child.draw(canvas);
  }

  @override
  bool hitTest(int px, int py) {
    _syncChildBounds();
    return child.hitTest(px, py);
  }

}

class Expanded extends Flexible {
  Expanded({required super.child, super.flex = 1}) : super(fit: FlexFit.tight);
}

class Flex extends Widget {
  final Axis direction;
  @override
  final List<Widget> children;
  int spacing;
  MainAxisAlignment mainAxisAlignment;
  CrossAxisAlignment crossAxisAlignment;

  Flex({
    required this.direction,
    this.spacing = 0,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    List<Widget>? children,
  }) : children = children ?? [];

  bool get _isHorizontal => direction == Axis.horizontal;

  Widget _unwrap(Widget child) {
    return child is Flexible ? child.child : child;
  }

  int _flexOf(Widget child) {
    if (child is Flexible) return child.flex;
    if (child is Spacer) return 1;
    return 0;
  }

  FlexFit _fitOf(Widget child) {
    if (child is Flexible) return child.fit;
    if (child is Spacer) return FlexFit.tight;
    return FlexFit.loose;
  }

  int _mainExtent(Widget child) {
    final actual = _unwrap(child);
    return _isHorizontal ? actual.width : actual.height;
  }

  int _crossExtent(Widget child) {
    final actual = _unwrap(child);
    return _isHorizontal ? actual.height : actual.width;
  }

  int _intrinsicCrossSize() {
    if (children.isEmpty) return 0;
    var maxCross = 0;
    for (final child in children) {
      final extent = _crossExtent(child);
      if (extent > maxCross) maxCross = extent;
    }
    return maxCross;
  }

  @override
  void performLayout(int containerWidth) {
    for (final c in children) {
      c.parent = this;
    }
    // Measure non-flex children intrinsically, then distribute flex space
    // and compute cross size — mirrors layout() but with intrinsic cross.
    width = containerWidth;
    // First pass: lay out non-flex children to get their intrinsic main size.
    // Flex children are not laid out yet; they will receive leftover space.
    for (final child in children) {
      if (_flexOf(child) == 0) {
        final actual = _unwrap(child);
        // Give non-flex children an unbounded main constraint so they keep
        // their intrinsic size (e.g. Button stays content-sized).
        actual.performLayout(0);
        // Also ensure Flexible wrapper syncs if needed.
        if (child is Flexible) {
          child.width = actual.width;
          child.height = actual.height;
        }
      }
    }
    // Delegate to layout() which handles flex distribution and positioning.
    // Use containerWidth for main axis, and 0 for cross (intrinsic).
    layout(containerWidth, 0);
  }

  void layout(int containerWidth, int containerHeight) {
    width = containerWidth;
    height = containerHeight > 0 ? containerHeight : _intrinsicCrossSize();

    final availableMain = _isHorizontal ? width : height;
    final availableCross = _isHorizontal ? height : width;
    final childCount = children.length;
    final spacingTotal = childCount > 0 ? spacing * (childCount - 1) : 0;

    var fixedMain = spacingTotal;
    var totalFlex = 0;
    for (final child in children) {
      final flex = _flexOf(child);
      if (flex > 0) {
        totalFlex += flex;
      } else {
        fixedMain += _mainExtent(child);
      }
    }

    var remainingMain = availableMain - fixedMain;
    if (remainingMain < 0) remainingMain = 0;

    final allocatedMain = <Widget, int>{};
    final flexChildren = children.where((child) => _flexOf(child) > 0).toList();
    var allocatedFlexMain = 0;
    for (var i = 0; i < flexChildren.length; i++) {
      final child = flexChildren[i];
      final flex = _flexOf(child);
      final share = i == flexChildren.length - 1
          ? remainingMain - allocatedFlexMain
          : (remainingMain * flex) ~/ totalFlex;
      allocatedFlexMain += share;
      final actual = _unwrap(child);
      final intrinsic = _mainExtent(child);
      final size = _fitOf(child) == FlexFit.tight
          ? share
          : (intrinsic == 0 ? share : intrinsic > share ? share : intrinsic);
      allocatedMain[child] = size;
      if (actual is Spacer) {
        allocatedMain[actual] = size;
      }
    }

    final totalUsedMain = children.fold<int>(
      spacingTotal,
      (sum, child) => sum + (allocatedMain[child] ?? _mainExtent(child)),
    );
    var freeMain = availableMain - totalUsedMain;
    if (freeMain < 0) freeMain = 0;

    int leading = 0;
    int betweenExtra = 0;
    if (mainAxisAlignment == MainAxisAlignment.center) {
      leading = freeMain ~/ 2;
    } else if (mainAxisAlignment == MainAxisAlignment.end) {
      leading = freeMain;
    } else if (mainAxisAlignment == MainAxisAlignment.spaceBetween) {
      if (childCount > 1) {
        betweenExtra = freeMain ~/ (childCount - 1);
      } else {
        leading = freeMain;
      }
    } else if (mainAxisAlignment == MainAxisAlignment.spaceAround) {
      if (childCount > 0) {
        betweenExtra = freeMain ~/ childCount;
        leading = betweenExtra ~/ 2;
      }
    } else if (mainAxisAlignment == MainAxisAlignment.spaceEvenly) {
      if (childCount > 0) {
        betweenExtra = freeMain ~/ (childCount + 1);
        leading = betweenExtra;
      }
    }

    var mainCursor = leading;
    for (final child in children) {
      final actual = _unwrap(child);
      final assignedMain = allocatedMain[child] ?? _mainExtent(child);
      final assignedCross = crossAxisAlignment == CrossAxisAlignment.stretch
          ? availableCross
          : _crossExtent(child);
      final resolvedCross = assignedCross > 0 ? assignedCross : availableCross;
      final crossOffset = switch (crossAxisAlignment) {
        CrossAxisAlignment.start => 0,
        CrossAxisAlignment.center => (availableCross - resolvedCross) ~/ 2,
        CrossAxisAlignment.end => availableCross - resolvedCross,
        CrossAxisAlignment.stretch => 0,
      };

      if (_isHorizontal) {
        child.x = x + mainCursor;
        child.y = y + crossOffset;
        child.width = assignedMain;
        child.height = resolvedCross;
        actual
          ..x = child.x
          ..y = child.y
          ..width = child.width
          ..height = child.height;
      } else {
        child.x = x + crossOffset;
        child.y = y + mainCursor;
        child.width = resolvedCross;
        child.height = assignedMain;
        actual
          ..x = child.x
          ..y = child.y
          ..width = child.width
          ..height = child.height;
      }

      mainCursor += assignedMain + spacing + betweenExtra;
    }
  }

  @override
  void draw(Painter canvas) {
    layout(width, height);
    for (final child in children) {
      child.draw(canvas);
    }
  }

  @override
  bool hitTest(int px, int py) {
    layout(width, height);
    if (!super.hitTest(px, py)) return false;
    for (final child in children.reversed) {
      if (child.hitTest(px, py)) return true;
    }
    return false;
  }
}

class Row extends Flex {
  Row({
    super.spacing = 0,
    super.mainAxisAlignment = MainAxisAlignment.start,
    super.crossAxisAlignment = CrossAxisAlignment.start,
    super.children,
  }) : super(direction: Axis.horizontal);
}

class Column extends Flex {
  Column({
    super.spacing = 0,
    super.mainAxisAlignment = MainAxisAlignment.start,
    super.crossAxisAlignment = CrossAxisAlignment.start,
    super.children,
  }) : super(direction: Axis.vertical);
}
