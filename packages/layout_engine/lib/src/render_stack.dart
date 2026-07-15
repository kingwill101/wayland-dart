/// Stack layout: [RenderStack] layers children atop each other.
///
/// Ported from artisanal (RenderStack), stripped of UV rendering.
library;

import 'dart:math' as math;

import 'geometry.dart';
import 'render_object.dart';

/// How to size non-positioned children in a stack.
enum StackFit { loose, tight, expand }

/// How visible overflow should be handled.
enum Overflow { visible, clip }

/// Two-dimensional alignment.
class Alignment {
  final double x;
  final double y;
  const Alignment(this.x, this.y);
  static const topLeft = Alignment(-1, -1);
  static const topCenter = Alignment(0, -1);
  static const topRight = Alignment(1, -1);
  static const centerLeft = Alignment(-1, 0);
  static const center = Alignment(0, 0);
  static const centerRight = Alignment(1, 0);
  static const bottomLeft = Alignment(-1, 1);
  static const bottomCenter = Alignment(0, 1);
  static const bottomRight = Alignment(1, 1);
}

/// Positioning data for a child of [RenderStack].
class StackParentData {
  final double? left;
  final double? right;
  final double? top;
  final double? bottom;
  final double? width;
  final double? height;

  const StackParentData({
    this.left,
    this.right,
    this.top,
    this.bottom,
    this.width,
    this.height,
  });

  bool get isPositioned =>
      left != null || right != null || top != null || bottom != null ||
      width != null || height != null;
}

/// Render object that stacks children (last child paints on top).
///
/// Non-positioned children are laid out according to [alignment] and [fit].
/// Positioned children (via [StackParentData]) are placed at explicit offsets.
class RenderStack extends RenderBox {
  Alignment alignment;
  StackFit fit;
  Overflow clipBehavior;

  RenderStack({
    this.alignment = Alignment.topLeft,
    this.fit = StackFit.loose,
    this.clipBehavior = Overflow.clip,
  });

  @override
  void layout(BoxConstraints constraints) {
    // Phase 1: layout children.
    var hasNonPositioned = false;
    for (final child in children) {
      if (_getParentData(child)?.isPositioned == true) {
        // Positioned child: size constrained by the stack's size.
        final data = _getParentData(child)!;
        var childConstraints = constraints;
        if (data.width != null) {
          childConstraints = childConstraints.tighten(width: data.width);
        }
        if (data.height != null) {
          childConstraints = childConstraints.tighten(height: data.height);
        }
        if (data.left != null && data.right != null) {
          childConstraints = childConstraints.tighten(
              width: constraints.maxWidth - data.left! - data.right!);
        }
        if (data.top != null && data.bottom != null) {
          childConstraints = childConstraints.tighten(
              height: constraints.maxHeight - data.top! - data.bottom!);
        }
        child.layout(childConstraints);
      } else {
        // Non-positioned child.
        hasNonPositioned = true;
        final childConstraints = fit == StackFit.loose
            ? constraints.loosen()
            : fit == StackFit.tight
                ? BoxConstraints.tight
                : constraints;
        child.layout(childConstraints);
      }
    }

    // Phase 2: compute stack size from non-positioned children.
    double maxW = 0, maxH = 0;
    if (hasNonPositioned) {
      for (final child in children) {
        if (_getParentData(child)?.isPositioned != true) {
          if (child.size.width > maxW) maxW = child.size.width;
          if (child.size.height > maxH) maxH = child.size.height;
        }
      }
    }
    // Account for positioned children that extend beyond.
    for (final child in children) {
      final data = _getParentData(child);
      if (data?.isPositioned == true) {
        final right = data!.right ?? data.left ?? 0;
        final bottom = data.bottom ?? data.top ?? 0;
        if (child.size.width + right > maxW) maxW = child.size.width + right;
        if (child.size.height + bottom > maxH) maxH = child.size.height + bottom;
      }
    }
    size = constraints.constrain(Size(maxW, maxH));

    // Phase 3: position children.
    for (final child in children) {
      child.offset = _resolveChildOffset(child, _getParentData(child));
    }
  }

  Offset _resolveChildOffset(RenderObject child, StackParentData? data) {
    final targetW = size.width;
    final targetH = size.height;
    final childW = child.size.width;
    final childH = child.size.height;

    if (data != null && data.isPositioned) {
      final left = data.left;
      final right = data.right;
      final top = data.top;
      final bottom = data.bottom;

      final x = left ??
          (right != null
              ? targetW - childW - right
              : ((alignment.x + 1) / 2 * (targetW - childW)));
      final y = top ??
          (bottom != null
              ? targetH - childH - bottom
              : ((alignment.y + 1) / 2 * (targetH - childH)));
      return Offset(x, y);
    }

    // Non-positioned: align within stack.
    final x = (alignment.x + 1) / 2 * (targetW - childW);
    final y = (alignment.y + 1) / 2 * (targetH - childH);
    return Offset(x.clamp(0, targetW), y.clamp(0, targetH));
  }

  StackParentData? _getParentData(RenderObject child) => child.parentData as StackParentData?;
}
