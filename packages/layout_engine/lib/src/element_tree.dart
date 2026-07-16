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

  /// Callback invoked when any element is marked dirty.
  /// Set by the framework (e.g., WidgetWindow) to schedule repaint.
  NeedsBuildCallback? onNeedsBuild;

  /// Whether any elements are waiting to be rebuilt.
  bool get hasDirty => _dirty.isNotEmpty;

  /// Whether a paint pass is needed after the last build scope.
  bool get needsPaint => _needsPaint;

  /// Schedule [element] for rebuild.
  void scheduleBuildFor(Element element) {
    _dirty.add(element);
    onNeedsBuild?.call();
  }

  /// Called by an element after it finishes rebuilding.
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

  /// Find the nearest inherited widget of type [T] and register as dependent.
  T? dependOnInheritedWidgetOfExactType<T extends InheritedWidget>() {
    var current = _element.parent;
    while (current != null) {
      if (current is InheritedElement && current.widget is T) {
        current._addDependent(_element);
        return current.widget as T;
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

  /// The renderable widget output (e.g., result of [State.build]).
  /// Defaults to [widget] for plain widgets.
  ElementWidget get renderWidget => widget;

  Element(this.widget) {
    context = BuildContext(this);
  }

  /// Mount this element as a child of [parent].
  /// Marks the element dirty so it participates in the next build scope.
  void mount(Element? parent) {
    this.parent = parent;
    _depth = parent != null ? parent._depth + 1 : 0;
    markNeedsBuild();
  }

  /// Update this element with a new widget configuration.
  void update(ElementWidget newWidget) {
    widget = newWidget;
  }

  /// Rebuild this element if it is currently dirty.
  /// Calls [performRebuild] after clearing the dirty flag.
  void rebuild() {
    if (!_dirty) return;
    _dirty = false;
    owner?.didRebuild(this);
    performRebuild();
  }

  /// Called during rebuild to update child elements.
  /// Override in subclasses that manage children.
  void performRebuild() {}

  /// Mark this element as needing rebuild.
  /// The element will be rebuilt in the next [BuildOwner.buildScope].
  void markNeedsBuild() {
    if (_dirty) return;
    _dirty = true;
    owner?.scheduleBuildFor(this);
  }

  /// Reconcile children with a list of [newWidgets].
  /// Matches by runtimeType + key, preserving element state across
  /// position changes when keys match. Handles insert, remove, reorder.
  void updateChildren(List<ElementWidget> newWidgets) {
    final oldLen = children.length;
    final newLen = newWidgets.length;
    var i = 0;
    while (i < oldLen && i < newLen &&
        ElementWidget.canUpdate(children[i].widget, newWidgets[i])) {
      if (!identical(children[i].widget, newWidgets[i])) {
        children[i].update(newWidgets[i]);
        children[i].markNeedsBuild();
      }
      i++;
    }
    if (i == oldLen && i == newLen) return;

    // Build key map of remaining old children.
    final keyed = <Object, Element>{};
    for (var j = oldLen - 1; j >= i; j--) {
      final child = children[j];
      if (child.widget.key != null) {
        keyed[child.widget.key!] = child;
      } else {
        child.unmount();
        children.removeAt(j);
      }
    }

    // Walk remaining new widgets, match by key or create.
    for (var j = i; j < newLen; j++) {
      final newW = newWidgets[j];
      final key = newW.key;
      Element? matched;
      if (key != null && keyed.containsKey(key)) {
        matched = keyed.remove(key)!;
      }
      if (matched != null) {
        children.remove(matched);
        children.insert(j, matched);
        matched.update(newW);
        matched.markNeedsBuild();
      } else {
        final child = createElement(newW);
        final pos = j < children.length ? j : children.length;
        children.insert(pos, child);
        child.owner = owner;
        child.mount(this);
      }
    }

    // Unmount remaining unmatched keyed children.
    for (final oldChild in keyed.values) {
      children.remove(oldChild);
      oldChild.unmount();
    }
  }


  // ── Focus navigation ──────────────────────────────────────

  /// Whether this element can receive keyboard focus.
  /// Set by the framework (e.g., WidgetWindow syncs from Widget.isFocusable).
  bool focusable = false;

  /// Called when this element receives focus.
  void onFocus() {}

  /// Called when this element loses focus.
  void onBlur() {}

  /// Find the next focusable element depth-first from [root].
  /// Returns the first focusable element after [current], or null.
  static Element? findNextFocus(Element root, {Element? current}) {
    bool found = current == null;
    return _searchFocus(root, current, found);
  }

  /// Find the previous focusable element (reverse depth-first).
  static Element? findPreviousFocus(Element root, {Element? current}) {
    Element? previous;
    _searchFocusReverse(root, current, (el) {
      previous = el;
    });
    return previous;
  }

  static Element? _searchFocus(Element el, Element? current, bool found) {
    if (el.focusable && found && el != current) return el;
    if (identical(el, current)) found = true;
    for (final child in el.children) {
      final result = _searchFocus(child, current, found);
      if (result != null) return result;
      if (identical(child, current)) found = true;
    }
    return null;
  }

  static void _searchFocusReverse(Element el, Element? current, void Function(Element) onFound) {
    if (identical(el, current)) return;
    if (el.focusable) onFound(el);
    for (var i = el.children.length - 1; i >= 0; i--) {
      _searchFocusReverse(el.children[i], current, onFound);
    }
  }

  /// Hit-test through the element tree.
  ///
  /// [pointInBounds] is a framework-provided callback that checks
  /// whether (x, y) is within a widget's bounds. This keeps the
  /// element tree framework-agnostic — the rendering framework
  /// (e.g., window_toolkit) provides bounds from Widget x/y/w/h.
  ///
  /// Returns the deepest matching element, or null.
  Element? hitTest(double x, double y, bool Function(ElementWidget w) pointInBounds) {
    // Use renderWidget for bounds check — StatefulElement/StatelessElement
    // have configuration widgets (e.g., CounterWidget) that don't have
    // rendering bounds. renderWidget returns the built/rendered output.
    if (!pointInBounds(renderWidget)) return null;
    for (var i = children.length - 1; i >= 0; i--) {
      final result = children[i].hitTest(x, y, pointInBounds);
      if (result != null) return result;
    }
    return this;
  }

  /// Unmount and dispose this element.
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
  ElementWidget get renderWidget {
    if (children.isNotEmpty) return children.first.widget;
    return widget;
  }

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
      if (ElementWidget.canUpdate(child.widget, newWidget)) {
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
  ElementWidget get renderWidget {
    if (children.isNotEmpty) return children.first.widget;
    return widget;
  }

  ElementWidget get builtWidget => renderWidget;

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
      if (ElementWidget.canUpdate(child.widget, newWidget)) {
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
// InheritedElement — propagates data down the tree
// ---------------------------------------------------------------------------

class InheritedElement extends Element {
  final Set<Element> _dependents = {};

  InheritedElement(super.widget);

  /// Register [dependent] to be rebuilt when this widget changes.
  void _addDependent(Element dependent) {
    _dependents.add(dependent);
  }

  @override
  void update(ElementWidget newWidget) {
    final old = widget as InheritedWidget;
    super.update(newWidget);
    // Notify dependents if the widget says data changed.
    if ((newWidget as InheritedWidget).updateShouldNotify(old)) {
      for (final d in _dependents) {
        d.markNeedsBuild();
      }
    }
  }

  @override
  void performRebuild() {
    final w = widget as InheritedWidget;
    _updateChild(0, w.child);
  }

  void _updateChild(int index, ElementWidget newWidget) {
    if (index >= children.length) {
      final child = createElement(newWidget);
      children.add(child);
      child.owner = owner;
      child.mount(this);
    } else {
      final child = children[index];
      if (ElementWidget.canUpdate(child.widget, newWidget)) {
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
/// Create the appropriate [Element] subclass for [widget].
///
/// - [StatefulWidget] → [StatefulElement]
/// - [StatelessWidget] → [StatelessElement]
/// - [InheritedWidget] → [InheritedElement]
/// - Other → [WidgetElement]
Element createElement(ElementWidget widget) {
  if (widget is StatefulWidget) return StatefulElement(widget);
  if (widget is StatelessWidget) return StatelessElement(widget);
  if (widget is InheritedWidget) return InheritedElement(widget);
  return WidgetElement(widget);
}
