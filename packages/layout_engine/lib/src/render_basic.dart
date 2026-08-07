/// Single-child layout primitives: constrain, align, aspect ratio, limit.
///
/// Host toolkits adapt paintables into [RenderBox] children and compose these
/// objects rather than re-implementing geometry.
///
/// | Class | Toolkit analogue |
/// |-------|------------------|
/// | [RenderConstrainedBox] | SizedBox / ConstrainedBox |
/// | [RenderPositionedBox] | Align / Center |
/// | [RenderAspectRatio] | AspectRatio |
/// | [RenderLimitedBox] | LimitedBox |
/// | [RenderFractionallySizedBox] | FractionallySizedBox |
/// | [RenderCustomSingleChildLayout] | CustomSingleChildLayout |
///
/// {@category Render objects}
library;

import 'dart:math' as math;

import 'geometry.dart';
import 'render_object.dart';
import 'render_stack.dart' show Alignment;

/// Base for single-child boxes with a [child] getter and helpers.
abstract class RenderSingleChildBox extends RenderBox {
  /// The first child as a [RenderBox], or null.
  RenderBox? get child =>
      children.isEmpty ? null : children.first as RenderBox;

  /// Lays out [child] under [constraints] and returns its size (or zero).
  Size layoutChild(BoxConstraints constraints) {
    final c = child;
    if (c == null) return Size.zero;
    c.layout(constraints);
    return c.size;
  }

  /// Sets the child's [RenderObject.offset] when a child is present.
  void positionChild(Offset offset) {
    final c = child;
    if (c != null) c.offset = offset;
  }
}

/// Passes constraints through and sizes itself to the child.
///
/// Useful as a hook (opacity, listeners) without changing geometry.
class RenderProxyBox extends RenderSingleChildBox {
  @override
  void layout(BoxConstraints constraints) {
    this.constraints = constraints;
    final c = child;
    if (c == null) {
      size = constraints.constrain(Size.zero);
      return;
    }
    c.layout(constraints);
    size = c.size;
    c.offset = Offset.zero;
  }
}

/// Applies [additionalConstraints] on top of parent constraints.
///
/// ```dart
/// // SizedBox(width: 64, height: 32)
/// RenderConstrainedBox(
///   additionalConstraints: BoxConstraints.tightFor(width: 64, height: 32),
/// )..attach(child);
///
/// // ConstrainedBox(minWidth: 100)
/// RenderConstrainedBox(
///   additionalConstraints: const BoxConstraints(minWidth: 100),
/// )..attach(child);
/// ```
class RenderConstrainedBox extends RenderSingleChildBox {
  /// Extra min/max bounds intersected with the parent constraints.
  BoxConstraints additionalConstraints;

  /// Creates a box that enforces [additionalConstraints].
  RenderConstrainedBox({
    this.additionalConstraints = const BoxConstraints(),
  });

  @override
  void layout(BoxConstraints constraints) {
    this.constraints = constraints;
    final childConstraints = additionalConstraints.enforce(constraints);
    final c = child;
    if (c == null) {
      size = childConstraints.constrain(Size.zero);
      return;
    }
    c.layout(childConstraints);
    size = childConstraints.constrain(c.size);
    c.offset = Offset.zero;
  }
}

/// Expands within constraints and positions the child by [alignment].
///
/// Toolkit analogue of Align / Center. When [widthFactor] / [heightFactor]
/// are null and the axis is bounded, that axis expands to the max constraint.
/// Set a factor of `1.0` to hug the child on that axis instead.
///
/// ```dart
/// RenderPositionedBox(alignment: Alignment.center)..attach(child);
/// ```
class RenderPositionedBox extends RenderSingleChildBox {
  /// Where to place the child inside this box.
  Alignment alignment;

  /// If non-null, this width is `childWidth * widthFactor` (then constrained).
  double? widthFactor;

  /// If non-null, this height is `childHeight * heightFactor` (then constrained).
  double? heightFactor;

  /// Creates an aligning box.
  RenderPositionedBox({
    this.alignment = Alignment.center,
    this.widthFactor,
    this.heightFactor,
  })  : assert(widthFactor == null || widthFactor >= 0),
        assert(heightFactor == null || heightFactor >= 0);

  @override
  void layout(BoxConstraints constraints) {
    this.constraints = constraints;
    final c = child;

    final loose = constraints.loosen();
    final childSize = c == null
        ? Size.zero
        : () {
            c.layout(loose);
            return c.size;
          }();

    final w = widthFactor == null
        ? (constraints.hasBoundedWidth
            ? constraints.maxWidth
            : childSize.width)
        : childSize.width * widthFactor!;
    final h = heightFactor == null
        ? (constraints.hasBoundedHeight
            ? constraints.maxHeight
            : childSize.height)
        : childSize.height * heightFactor!;

    size = constraints.constrain(Size(w, h));

    if (c != null) {
      // Alignment.x/y are in -1…1; map to child top-left inside our size.
      final dx = (size.width - childSize.width) * ((alignment.x + 1) / 2);
      final dy = (size.height - childSize.height) * ((alignment.y + 1) / 2);
      c.offset = Offset(
        dx.isFinite ? dx : 0,
        dy.isFinite ? dy : 0,
      );
    }
  }
}

/// Sizes itself to [aspectRatio] (`width / height`) within parent constraints.
class RenderAspectRatio extends RenderSingleChildBox {
  /// Width divided by height (must be positive).
  double aspectRatio;

  /// Creates a box with the given [aspectRatio].
  RenderAspectRatio({required this.aspectRatio})
      : assert(aspectRatio > 0, 'aspectRatio must be > 0');

  @override
  void layout(BoxConstraints constraints) {
    this.constraints = constraints;
    size = _applyAspect(constraints);

    final c = child;
    if (c != null) {
      c.layout(BoxConstraints.tightFor(width: size.width, height: size.height));
      c.offset = Offset.zero;
    }
  }

  Size _applyAspect(BoxConstraints constraints) {
    if (!constraints.isNormalized) {
      return constraints.constrain(Size.zero);
    }

    // Prefer max width when bounded; fall back to max height.
    double width = constraints.maxWidth;
    double height;

    if (width.isFinite) {
      height = width / aspectRatio;
      if (height > constraints.maxHeight) {
        height = constraints.maxHeight;
        width = height * aspectRatio;
      }
      if (width < constraints.minWidth) {
        width = constraints.minWidth;
        height = width / aspectRatio;
      }
      if (height < constraints.minHeight) {
        height = constraints.minHeight;
        width = height * aspectRatio;
      }
    } else if (constraints.maxHeight.isFinite) {
      height = constraints.maxHeight;
      width = height * aspectRatio;
    } else {
      width = constraints.minWidth;
      height = width / aspectRatio;
    }

    return constraints.constrain(Size(width, height));
  }
}

/// Caps max size when the parent is unbounded (scroll content soft limits).
///
/// When the parent axis is already bounded, that bound is used unchanged.
class RenderLimitedBox extends RenderSingleChildBox {
  /// Maximum width when the parent max width is infinite.
  double maxWidth;

  /// Maximum height when the parent max height is infinite.
  double maxHeight;

  /// Creates a limited box with the given soft caps.
  RenderLimitedBox({
    this.maxWidth = double.infinity,
    this.maxHeight = double.infinity,
  })  : assert(maxWidth >= 0),
        assert(maxHeight >= 0);

  @override
  void layout(BoxConstraints constraints) {
    this.constraints = constraints;
    final limited = BoxConstraints(
      minWidth: constraints.minWidth,
      maxWidth: constraints.hasBoundedWidth
          ? constraints.maxWidth
          : math.min(constraints.maxWidth, maxWidth),
      minHeight: constraints.minHeight,
      maxHeight: constraints.hasBoundedHeight
          ? constraints.maxHeight
          : math.min(constraints.maxHeight, maxHeight),
    );
    final c = child;
    if (c == null) {
      size = limited.constrain(Size.zero);
      return;
    }
    c.layout(limited);
    size = constraints.constrain(c.size);
    c.offset = Offset.zero;
  }
}

/// Sizes the child as a fraction of the parent's max size on each axis.
///
/// Each non-null factor requires a bounded parent axis.
class RenderFractionallySizedBox extends RenderSingleChildBox {
  /// Child width as a fraction of parent max width, or null to pass through.
  double? widthFactor;

  /// Child height as a fraction of parent max height, or null to pass through.
  double? heightFactor;

  /// Alignment of the child inside this box.
  Alignment alignment;

  /// Creates a fractionally sized box.
  RenderFractionallySizedBox({
    this.widthFactor,
    this.heightFactor,
    this.alignment = Alignment.center,
  })  : assert(widthFactor == null || widthFactor >= 0),
        assert(heightFactor == null || heightFactor >= 0);

  @override
  void layout(BoxConstraints constraints) {
    this.constraints = constraints;
    assert(
      (widthFactor == null || constraints.hasBoundedWidth) &&
          (heightFactor == null || constraints.hasBoundedHeight),
      'RenderFractionallySizedBox needs a bounded axis for each non-null factor',
    );

    final maxW = constraints.maxWidth;
    final maxH = constraints.maxHeight;
    final childConstraints = BoxConstraints(
      minWidth: widthFactor != null ? maxW * widthFactor! : constraints.minWidth,
      maxWidth: widthFactor != null ? maxW * widthFactor! : constraints.maxWidth,
      minHeight:
          heightFactor != null ? maxH * heightFactor! : constraints.minHeight,
      maxHeight:
          heightFactor != null ? maxH * heightFactor! : constraints.maxHeight,
    );

    final c = child;
    final childSize = c == null
        ? childConstraints.constrain(Size.zero)
        : () {
            c.layout(childConstraints);
            return c.size;
          }();

    size = constraints.constrain(Size(
      widthFactor != null ? maxW : childSize.width,
      heightFactor != null ? maxH : childSize.height,
    ));

    if (c != null) {
      final dx = (size.width - childSize.width) * ((alignment.x + 1) / 2);
      final dy = (size.height - childSize.height) * ((alignment.y + 1) / 2);
      c.offset = Offset(dx.isFinite ? dx : 0, dy.isFinite ? dy : 0);
    }
  }
}

/// Swaps axes for layout by [quarterTurns] (0–3 clockwise).
///
/// Painting rotation remains the host toolkit's responsibility; this object
/// only exchanges width/height constraints and size.
class RenderRotatedBox extends RenderSingleChildBox {
  /// Number of 90° clockwise turns (0–3).
  int quarterTurns;

  /// Creates a rotated layout box.
  RenderRotatedBox({this.quarterTurns = 1})
      : assert(quarterTurns >= 0 && quarterTurns <= 3);

  bool get _swapsAxes => quarterTurns.isOdd;

  @override
  void layout(BoxConstraints constraints) {
    this.constraints = constraints;
    final c = child;
    if (c == null) {
      size = constraints.constrain(Size.zero);
      return;
    }

    final childConstraints = _swapsAxes
        ? BoxConstraints(
            minWidth: constraints.minHeight,
            maxWidth: constraints.maxHeight,
            minHeight: constraints.minWidth,
            maxHeight: constraints.maxWidth,
          )
        : constraints;

    c.layout(childConstraints);
    size = constraints.constrain(
      _swapsAxes
          ? Size(c.size.height, c.size.width)
          : c.size,
    );
    // Child origin; host may apply paint rotation around center.
    c.offset = Offset.zero;
  }
}

/// Callback for [RenderCustomSingleChildLayout].
///
/// Must call [setSize] with this node's size. Optionally lay out [child] and
/// call [setChildOffset].
typedef CustomSingleChildLayoutCallback = void Function(
  RenderBox? child,
  BoxConstraints constraints,
  void Function(Size size) setSize,
  void Function(Offset offset) setChildOffset,
);

/// Escape hatch for one-off geometry (dialogs, tooltips, badges).
///
/// ```dart
/// RenderCustomSingleChildLayout((child, c, setSize, setOffset) {
///   child!.layout(const BoxConstraints.tightFor(width: 24, height: 24));
///   setSize(const Size(100, 100));
///   setOffset(const Offset(70, 70));
/// });
/// ```
class RenderCustomSingleChildLayout extends RenderSingleChildBox {
  /// Invoked each layout pass to size this node and place the child.
  CustomSingleChildLayoutCallback performLayoutCallback;

  /// Creates a custom layout using [performLayoutCallback].
  RenderCustomSingleChildLayout(this.performLayoutCallback);

  @override
  void layout(BoxConstraints constraints) {
    this.constraints = constraints;
    final c = child;
    performLayoutCallback(
      c,
      constraints,
      (s) => size = constraints.constrain(s),
      (o) {
        if (c != null) c.offset = o;
      },
    );
  }
}
