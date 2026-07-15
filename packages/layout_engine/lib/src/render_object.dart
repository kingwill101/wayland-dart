/// Render object layer for widget layout.
library;

import 'geometry.dart';

/// A node in the layout tree.
abstract class RenderObject {
  RenderObject? parent;
  final List<RenderObject> children = [];
  Size size = Size.zero;
  Offset offset = Offset.zero;
  BoxConstraints constraints = const BoxConstraints();

  /// Per-child data for special layout (stack positioning, flex sizing, etc.).
  /// Cast to the appropriate parent data type when reading.
  Object? parentData;

  void attach(RenderObject child) {
    children.add(child);
    child.parent = this;
  }

  void detach(RenderObject child) {
    if (!identical(child.parent, this)) return;
    children.remove(child);
    child.parent = null;
  }

  void layout(BoxConstraints constraints) {
    this.constraints = constraints;
    size = constraints.constrain(Size.zero);
  }

  bool hitTest(HitTestResult result, {required double localX, required double localY}) {
    if (localX < 0 || localY < 0 || localX >= size.width || localY >= size.height) {
      return false;
    }
    // Test children in reverse order (last painted = on top).
    for (var i = children.length - 1; i >= 0; i--) {
      final child = children[i];
      final childX = localX - child.offset.dx;
      final childY = localY - child.offset.dy;
      if (childX < 0 || childY < 0 ||
          childX >= child.size.width || childY >= child.size.height) {
        continue;
      }
      if (child.hitTest(result, localX: childX, localY: childY)) {
        break; // deepest hit found, collect full ancestor path
      }
    }
    // Add ourselves to the result path (deepest → root order).
    result.add(HitTestEntry(this, localX, localY));
    return true;
  }

  void transform(Offset transform) {
    offset += transform;
    for (final child in children) {
      child.transform(transform);
    }
  }
}

/// Per-child layout data stored on a [RenderObject] by its parent.
class ParentData {
  Offset offset = Offset.zero;
}

/// A render object that may have a single child.
abstract class RenderBox extends RenderObject {}

/// Concrete [RenderBox] that delegates layout.
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
