/// Render object layer for widget layout.
///
/// Framework-agnostic layout tree. Concrete render objects (RenderRow,
/// RenderColumn, etc.) calculate sizes and positions in [layout], then
/// wait for the host framework to paint them.
library;

import 'geometry.dart';

/// A node in the layout tree.
abstract class RenderObject {
  RenderObject? parent;
  final List<RenderObject> children = [];
  Size size = Size.zero;
  Offset offset = Offset.zero;
  BoxConstraints constraints = const BoxConstraints();

  void attach(RenderObject child) {
    children.add(child);
    child.parent = this;
  }

  void detach(RenderObject child) {
    if (!identical(child.parent, this)) return;
    children.remove(child);
    child.parent = null;
  }

  /// Lay out this node given [constraints].
  /// Sets [size] and positions children via their [offset].
  void layout(BoxConstraints constraints) {
    this.constraints = constraints;
    size = constraints.constrain(Size.zero);
  }

  /// Walk the tree collecting hit results at (x, y) in local coords.
  bool hitTest(HitTestResult result, {required double localX, required double localY}) {
    if (localX < 0 || localY < 0 || localX >= size.width || localY >= size.height) {
      return false;
    }
    for (var i = children.length - 1; i >= 0; i--) {
      final child = children[i];
      if (child.hitTest(result,
          localX: localX - child.offset.dx,
          localY: localY - child.offset.dy)) {
        return true;
      }
    }
    result.add(HitTestEntry(this, localX, localY));
    return true;
  }

  /// Apply [transform] to all child offsets.
  void transform(Offset transform) {
    offset += transform;
    for (final child in children) {
      child.transform(transform);
    }
  }
}

/// A render object with a single child.
abstract class RenderBox extends RenderObject {}

/// Concrete [RenderBox] that delegates layout and paint.
class RenderDelegateBox extends RenderBox {
  final void Function(RenderDelegateBox, BoxConstraints) layoutFn;
  final void Function(RenderDelegateBox)? _afterLayout;

  RenderDelegateBox(this.layoutFn, {void Function(RenderDelegateBox)? afterLayout})
      : _afterLayout = afterLayout;

  @override
  void layout(BoxConstraints constraints) {
    layoutFn(this, constraints);
    _afterLayout?.call(this);
  }
}
