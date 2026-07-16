/// Bridge between the Element tree and the imperative rendering tree.
///
/// Wraps a [StatefulWidget] or [StatelessWidget] so it can be placed
/// inside rendering containers (VBox, HBox, etc.) while still getting
/// Element tree lifecycle management (initState, dispose, setState).
///
/// ```dart
/// VBox(children: [
///   ElementHost(child: CounterWidget()),
///   Label('plain'),
/// ])
/// ```
library;

import 'package:layout_engine/layout_engine.dart' show BuildContext, ElementTree, ElementWidget, State, StatefulWidget, StatelessWidget;

import '../painter/painter.dart';
import '../widget.dart';

/// Wraps [child] in [ElementHost] if it's a StatefulWidget or StatelessWidget.
/// Use in container widgets to auto-wrap children.
Widget autoElement(ElementWidget child) {
  if (child is Widget) return child;
  if (child is StatefulWidget || child is StatelessWidget) {
    return ElementHost(child: child);
  }
  throw ArgumentError('Cannot wrap $child as Widget');
}

/// Apply [autoElement] to a list.
List<Widget> autoElementList(List<ElementWidget> items) {
  return [for (final item in items) autoElement(item)];
}

/// Wraps a [StatefulWidget] or [StatelessWidget] for use in the rendering tree.
///
/// Creates an [Element] tree internally to manage the child's lifecycle.
/// The child's `build()` output is drawn as a [Widget] using our rendering
/// pipeline.
class ElementHost extends Widget {
  final ElementWidget child;
  /// The internal element tree. Exposed for testing/state access.
  ElementTree? tree;

  ElementHost({required this.child}) {
    if (child is! Widget) {
      tree = ElementTree();
      tree!.mount(child);
      tree!.build();
    }
  }

  /// Rebuild the element tree if dirty.
  void _rebuildIfNeeded() {
    tree?.build();
  }

  /// Get the renderable output from the element tree.
  Widget? get _renderable {
    _rebuildIfNeeded();
    final render = tree?.root?.renderWidget;
    if (render is Widget) return render;
    return null;
  }

  @override
  void draw(Painter canvas) {
    final render = _renderable;
    if (render == null) return;
    render.x = x;
    render.y = y;
    render.width = width;
    render.height = height;
    render.draw(canvas);
  }

  @override
  void performLayout(int containerWidth) {
    final render = _renderable;
    if (render == null) return;
    // Propagate ElementHost's position/size to the renderable widget.
    render.x = x;
    render.y = y;
    render.width = width;
    render.height = height;
    render.performLayout(containerWidth);
    width = render.width;
    height = render.height;
  }

  @override
  bool hitTest(int px, int py) {
    if (!super.hitTest(px, py)) return false;
    final render = _renderable;
    if (render == null) return false;
    render.x = x;
    render.y = y;
    return render.hitTest(px, py);
  }

  /// Expose the built widget tree for hit-test and event traversal.
  @override
  List<Widget> get children {
    final render = _renderable;
    if (render == null) return const [];
    return [render];
  }

  @override
  void dispose() {
    tree?.unmount();
    super.dispose();
  }
}
