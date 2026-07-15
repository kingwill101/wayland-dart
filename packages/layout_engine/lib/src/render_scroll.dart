/// Scroll primitives: controller, physics, viewport render object.
library;

import 'dart:math' as math;

import 'geometry.dart';
import 'render_object.dart';

// ---------------------------------------------------------------------------
// ScrollController
// ---------------------------------------------------------------------------

/// Controls the scroll position of a viewport.
abstract class ScrollController {
  int get offset;
  int get viewportExtent;
  int get contentExtent;

  int get maxOffset => math.max(0, contentExtent - viewportExtent);
  double get scrollPercent => maxOffset == 0 ? 0 : offset / maxOffset;

  bool jumpTo(int offset);
  bool scrollBy(int delta);

  void addListener(void Function() listener);
  void removeListener(void Function() listener);
}

/// Concrete [ScrollController] for viewports.
class ViewportScrollController extends ScrollController {
  int _offset = 0;
  int _viewportExtent = 0;
  int _contentExtent = 0;
  final Set<void Function()> _listeners = {};

  @override
  int get offset => _offset;
  @override
  int get viewportExtent => _viewportExtent;
  @override
  int get contentExtent => _contentExtent;

  /// Update viewport and content extents after layout.
  void updateMetrics({int? viewportExtent, int? contentExtent}) {
    if (viewportExtent != null) _viewportExtent = viewportExtent;
    if (contentExtent != null) _contentExtent = contentExtent;
    _clampOffset();
    _notify();
  }

  @override
  bool jumpTo(int offset) {
    final clamped = offset.clamp(0, maxOffset);
    if (clamped == _offset) return false;
    _offset = clamped;
    _notify();
    return true;
  }

  @override
  bool scrollBy(int delta) {
    if (delta == 0) return false;
    final before = _offset;
    _offset = (_offset + delta).clamp(0, math.max(0, _contentExtent - _viewportExtent));
    if (_offset == before) return false;
    _notify();
    return true;
  }

  void _clampOffset() {
    final max = maxOffset;
    if (_offset > max) {
      _offset = max;
      _notify();
    }
  }

  void _notify() {
    for (final l in Set.of(_listeners)) {
      l();
    }
  }

  @override
  void addListener(void Function() listener) => _listeners.add(listener);
  @override
  void removeListener(void Function() listener) => _listeners.remove(listener);
}

// ---------------------------------------------------------------------------
// ScrollPhysics
// ---------------------------------------------------------------------------

/// Determines how a scroll view responds to user input.
abstract class ScrollPhysics {
  const ScrollPhysics();

  /// Apply boundary resistance to an overscroll delta.
  double applyBoundaryConditions(double offset, double delta);

  /// Clamp the final position.
  double clampPosition(double position, double min, double max);
}

/// Hard clamp at boundaries — no overshoot.
class ClampScrollPhysics extends ScrollPhysics {
  const ClampScrollPhysics();

  @override
  double applyBoundaryConditions(double offset, double delta) => delta;

  @override
  double clampPosition(double position, double min, double max) =>
      position.clamp(min, max);
}

/// Allows overshoot and bounce-back.
class BounceScrollPhysics extends ScrollPhysics {
  const BounceScrollPhysics();

  @override
  double applyBoundaryConditions(double offset, double delta) => delta;

  @override
  double clampPosition(double position, double min, double max) => position;
}

// ---------------------------------------------------------------------------
// RenderViewport — clips and scrolls a single child
// ---------------------------------------------------------------------------

/// Parent data for [RenderViewport] children.
class ViewportParentData extends ParentData {
  double scrollOffset = 0;
}

/// A render object that clips its child and applies a scroll offset.
///
/// The child is laid out with unconstrained height (or width for horizontal
/// scroll) and positioned at a negative scroll offset. The viewport clips to
/// its own size, showing only the visible portion of the child.
class RenderViewport extends RenderBox {
  ScrollController? controller;
  Axis scrollDirection;

  RenderViewport({
    this.controller,
    this.scrollDirection = Axis.vertical,
  });

  @override
  void layout(BoxConstraints constraints) {
    if (children.isEmpty) {
      size = constraints.constrain(Size.zero);
      return;
    }

    final child = children.first;
    // Lay out child with unbounded extent in scroll direction.
    final childConstraints = scrollDirection == Axis.vertical
        ? BoxConstraints(
            minWidth: constraints.minWidth,
            maxWidth: constraints.maxWidth,
            minHeight: 0,
            maxHeight: double.infinity,
          )
        : BoxConstraints(
            minWidth: 0,
            maxWidth: double.infinity,
            minHeight: constraints.minHeight,
            maxHeight: constraints.maxHeight,
          );
    child.layout(childConstraints);
    size = constraints.constrain(child.size);

    // Update controller extents.
    final ctrl = controller;
    if (ctrl is ViewportScrollController) {
      final contentExtent = scrollDirection == Axis.vertical
          ? child.size.height.round()
          : child.size.width.round();
      final viewportExtent = scrollDirection == Axis.vertical
          ? size.height.round()
          : size.width.round();
      ctrl.updateMetrics(
        viewportExtent: viewportExtent,
        contentExtent: contentExtent,
      );
    }

    // Position child at negative scroll offset.
    final off = scrollDirection == Axis.vertical
        ? Offset(0, -(ctrl?.offset ?? 0).toDouble())
        : Offset(-(ctrl?.offset ?? 0).toDouble(), 0);
    child.offset = off;
  }

  @override
  bool hitTest(HitTestResult result, {required double localX, required double localY}) {
    if (localX < 0 || localY < 0 ||
        localX >= size.width || localY >= size.height) {
      return false;
    }
    for (var i = children.length - 1; i >= 0; i--) {
      final child = children[i];
      final childX = localX - child.offset.dx;
      final childY = localY - child.offset.dy;
      if (childX < 0 || childY < 0 ||
          childX >= child.size.width || childY >= child.size.height) {
        continue;
      }
      if (child.hitTest(result, localX: childX, localY: childY)) {
        break;
      }
    }
    result.add(HitTestEntry(this, localX, localY));
    return true;
  }
}
