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

import 'package:layout_engine/layout_engine.dart';

import '../painter/painter.dart';
import '../widget.dart';

/// Wraps a [StatefulWidget] or [StatelessWidget] for use in the rendering tree.
///
/// Creates an [Element] tree internally to manage the child's lifecycle.
/// The child's `build()` output is drawn as a [Widget] using our rendering
/// pipeline.
class ElementHost extends Widget {
  final ElementWidget child;
  ElementTree? _tree;

  ElementHost({required this.child}) {
    if (child is StatefulWidget || child is StatelessWidget) {
      _tree = ElementTree();
      _tree!.mount(child);
      _tree!.build();
    }
  }

  /// Rebuild the element tree if dirty.
  void _rebuildIfNeeded() {
    _tree?.build();
  }

  /// Get the renderable output from the element tree.
  Widget? get _renderable {
    _rebuildIfNeeded();
    final render = _tree?.root?.renderWidget;
    if (render is Widget) return render;
    return null;
  }

  @override
  void draw(Painter canvas) {
    final render = _renderable;
    if (render == null) return;
    render
      ..x = x
      ..y = y
      ..width = width
      ..height = height;
    render.draw(canvas);
  }

  @override
  void performLayout(int containerWidth) {
    final render = _renderable;
    if (render == null) return;
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

  @override
  void dispose() {
    _tree?.unmount();
    super.dispose();
  }
}
