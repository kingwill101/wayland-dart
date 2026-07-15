/// Element tree: lifecycle, dirty tracking, rebuild, BuildContext.
///
/// Ported from artisanal, stripped of TEA (Cmd/Msg) dependencies.
/// Framework-agnostic — the widget type is abstracted as [ElementWidget].
library;

import 'framework.dart';

// ---------------------------------------------------------------------------
// BuildOwner — manages dirty elements and frame scheduling
// ---------------------------------------------------------------------------

/// Global callback when any element needs rebuild.
typedef NeedsBuildCallback = void Function();

/// Manages dirty element tracking and rebuild scheduling.
class BuildOwner {
  final Set<Element> _dirty = {};
  bool _inBuild = false;
  bool _needsPaint = false;

  /// Set by the framework to schedule a repaint.
  NeedsBuildCallback? onNeedsBuild;

  bool get hasDirty => _dirty.isNotEmpty;
  bool get needsPaint => _needsPaint;

  /// Schedule [element] for rebuild.
  void scheduleBuildFor(Element element) {
    _dirty.add(element);
    onNeedsBuild?.call();
  }

  /// Remove [element] from the dirty set after rebuild.
  void didRebuild(Element element) {
    _dirty.remove(element);
    _needsPaint = true;
  }

  /// Rebuild all dirty elements that are descendants of [root].
  /// Returns true if any elements were rebuilt.
  bool buildScope(Element root) {
    if (_dirty.isEmpty) return false;
    _inBuild = true;

    var built = false;
    var safety = 0;
    while (_dirty.isNotEmpty && safety < 1000) {
      safety++;
      final candidates = _dirty
          .where((e) => _isDescendantOf(e, root))
          .toList()
        ..sort((a, b) => a.depth.compareTo(b.depth));

      if (candidates.isEmpty) break;

      for (final element in candidates) {
        if (!_dirty.contains(element)) continue;
        if (_hasDirtyAncestor(element)) continue;
        _dirty.remove(element);
        element.rebuild();
        built = true;
      }
    }

    _inBuild = false;
    _needsPaint = true;
    return built;
  }

  bool _isDescendantOf(Element element, Element root) {
    if (identical(element, root)) return true;
    var current = element.parent;
    while (current != null) {
      if (identical(current, root)) return true;
      current = current.parent;
    }
    return false;
  }

  bool _hasDirtyAncestor(Element element) {
    var current = element.parent;
    while (current != null) {
      if (_dirty.contains(current)) return true;
      current = current.parent;
    }
    return false;
  }
}

// ---------------------------------------------------------------------------
// BuildContext
// ---------------------------------------------------------------------------

/// Location in the element tree for ancestor traversal.
class BuildContext {
  final Element _element;
  BuildContext(this._element);

  Element get element => _element;

  /// Find the nearest ancestor state of type [T].
  T? findAncestorStateOfType<T extends State>() {
    var current = _element.parent;
    while (current != null) {
      if (current is StatefulElement && current.state is T) {
        return current.state as T;
      }
      current = current.parent;
    }
    return null;
  }
}

// ---------------------------------------------------------------------------
// Element
// ---------------------------------------------------------------------------

/// A mounted instance of a widget in the element tree.
class Element {
  ElementWidget widget;
  Element? parent;
  final List<Element> children = [];
  late BuildContext context;
  BuildOwner? owner;
  bool _dirty = false;
  int _depth = 0;

  int get depth => _depth;

  Element(this.widget) {
    context = BuildContext(this);
  }

  void mount(Element? parent) {
    this.parent = parent;
    _depth = parent != null ? parent._depth + 1 : 0;
    markNeedsBuild();
  }

  void update(ElementWidget newWidget) {
    widget = newWidget;
  }

  void rebuild() {
    if (!_dirty) return;
    _dirty = false;
    owner?.didRebuild(this);
    performRebuild();
  }

  void performRebuild() {}

  void markNeedsBuild() {
    if (_dirty) return;
    _dirty = true;
    owner?.scheduleBuildFor(this);
  }

  void unmount() {
    for (final child in children) {
      child.unmount();
    }
    children.clear();
  }
}

// ---------------------------------------------------------------------------
// StatelessElement
// ---------------------------------------------------------------------------

class StatelessElement extends Element {
  StatelessElement(super.widget);

  @override
  void performRebuild() {
    final w = widget as StatelessWidget;
    final built = w.build(context);
    _updateChild(0, built as ElementWidget);
  }

  void _updateChild(int index, ElementWidget newWidget) {
    if (index >= children.length) {
      final child = createElement(newWidget);
      children.add(child);
      child.owner = owner;
      child.mount(this);
    } else {
      final child = children[index];
      if (child.widget.runtimeType == newWidget.runtimeType) {
        child.update(newWidget);
        child.markNeedsBuild();
      } else {
        child.unmount();
        final newChild = createElement(newWidget);
        children[index] = newChild;
        newChild.owner = owner;
        newChild.mount(this);
      }
    }
  }
}

// ---------------------------------------------------------------------------
// StatefulElement
// ---------------------------------------------------------------------------

class StatefulElement extends Element {
  final State state;

  StatefulElement(StatefulWidget w)
      : state = w.createState(),
        super(w) {
    state.markNeedsBuild = markNeedsBuild;
    (state as dynamic).widgetOverride = w;
    state.contextOverride = context;
  }

  @override
  void mount(Element? parent) {
    super.mount(parent);
    state.initState();
  }

  @override
  void update(ElementWidget newWidget) {
    final old = widget;
    super.update(newWidget);
    (state as dynamic).widgetOverride = newWidget;
    state.contextOverride = context;
    state.didUpdateWidget(old as StatefulWidget);
  }

  @override
  void performRebuild() {
    final built = state.build(context);
    _updateChild(0, built as ElementWidget);
  }

  void _updateChild(int index, ElementWidget newWidget) {
    if (index >= children.length) {
      final child = createElement(newWidget);
      children.add(child);
      child.owner = owner;
      child.mount(this);
    } else {
      final child = children[index];
      if (child.widget.runtimeType == newWidget.runtimeType) {
        child.update(newWidget);
        child.markNeedsBuild();
      } else {
        child.unmount();
        final newChild = createElement(newWidget);
        children[index] = newChild;
        newChild.owner = owner;
        newChild.mount(this);
      }
    }
  }

  @override
  void unmount() {
    state.dispose();
    state.markNeedsBuild = null;
    super.unmount();
  }
}

// ---------------------------------------------------------------------------
// WidgetElement — wraps a plain widget that draws directly
// ---------------------------------------------------------------------------

class WidgetElement extends Element {
  WidgetElement(super.widget);

  @override
  void performRebuild() {
    // Plain widgets draw directly — no child building.
  }
}

// ---------------------------------------------------------------------------
// Element tree root
// ---------------------------------------------------------------------------

/// Root of an element tree.
class ElementTree {
  Element? _root;
  final BuildOwner owner = BuildOwner();

  NeedsBuildCallback? get onNeedsBuild => owner.onNeedsBuild;
  set onNeedsBuild(NeedsBuildCallback? cb) => owner.onNeedsBuild = cb;

  Element? get root => _root;

  void mount(ElementWidget widget) {
    _root = createElement(widget);
    _root!.owner = owner;
    _root!.mount(null);
  }

  bool build() {
    if (_root == null) return false;
    return owner.buildScope(_root!);
  }

  void replaceRoot(ElementWidget newWidget) {
    if (_root == null) {
      mount(newWidget);
      return;
    }
    if (_root!.widget.runtimeType == newWidget.runtimeType) {
      _root!.update(newWidget);
      _root!.markNeedsBuild();
    } else {
      _root!.unmount();
      mount(newWidget);
    }
  }

  void unmount() {
    _root?.unmount();
    _root = null;
  }
}

// ---------------------------------------------------------------------------
// Element factory
// ---------------------------------------------------------------------------

Element createElement(ElementWidget widget) {
  if (widget is StatefulWidget) return StatefulElement(widget);
  if (widget is StatelessWidget) return StatelessElement(widget);
  return WidgetElement(widget);
}
