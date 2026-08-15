import 'painter/painter.dart';
import 'interaction.dart';
import 'widget.dart';
import 'widget_children.dart';
import 'widgets/element_host.dart';
import 'widgets/scroll_area.dart';

/// Shared focus state for widget-backed windows.
class FocusModel {
  Widget? focusedWidget;

  void requestFocus(Widget widget) {
    focusedWidget = widget;
  }

  void blur() {
    focusedWidget = null;
  }

  bool get hasFocus => focusedWidget != null;
}

/// Owns the widget-side lifecycle shared by xdg and layer-shell windows.
///
/// Wayland surface setup remains backend-specific, but the widget tree should
/// not know whether it is being drawn by an xdg toplevel or a layer surface.
/// This controller is the shared bridge: it mounts widgets, binds repaint
/// callbacks locally, lays out the root, and provides one hit-test/hover path.
class WidgetHostController {
  final VoidCallback? onRepaint;

  late Widget root;
  ElementTree? elementTree;
  final FocusModel focus = FocusModel();
  List<Widget> _hoverPath = const [];
  Widget? _dragTarget;
  int? _pressedButton;

  WidgetHostController(ElementWidget rootWidget, {this.onRepaint}) {
    _setRoot(rootWidget);
  }

  void _setRoot(ElementWidget rootWidget) {
    root = rootWidget is Widget ? rootWidget : ElementHost(child: rootWidget);

    if (rootWidget is StatefulWidget || rootWidget is StatelessWidget) {
      elementTree = ElementTree()
        ..onNeedsBuild = onRepaint
        ..mount(rootWidget);
    } else {
      _initializeWidgetTree(root);
    }
    bindRepaintCallbacks();
  }

  /// Plain widget trees do not use layout_engine's element lifecycle.
  void _initializeWidgetTree(Widget widget) {
    if (widget.mounted) return;
    widget.mounted = true;
    widget.initState();
    for (final child in childrenOf(widget)) {
      _initializeWidgetTree(child);
    }
  }

  /// Binds repaint ownership to this host instead of a process-global window.
  ///
  /// ElementHost can expose a new render widget after a rebuild, so this is
  /// intentionally cheap and repeated before layout as well as at startup.
  void bindRepaintCallbacks() {
    void bind(Widget widget) {
      widget.repaintCallback = onRepaint;
      for (final child in childrenOf(widget)) {
        bind(child);
      }
    }

    bind(root);
  }

  /// Rebuilds lifecycle-managed widgets, lays out the root, and binds any
  /// newly-created render widgets to this host.
  void layoutRoot(int width, int height) {
    elementTree?.build();
    bindRepaintCallbacks();
    root
      ..x = 0
      ..y = 0
      ..width = width
      ..height = height;
    root.performLayout(width);
  }

  void draw(Painter painter, {required int width, required int height}) {
    layoutRoot(width, height);
    root.draw(painter);
  }

  /// Collects the ancestor-to-deepest hit path at ([px], [py]).
  List<Widget> hitTestPath(
    Widget widget,
    int px,
    int py, [
    int offX = 0,
    int offY = 0,
  ]) {
    if (widget is ScrollArea) {
      final localPx = px + widget.scrollX + offX;
      final localPy = py + widget.scrollY + offY;
      if (widget.isOnScrollbar(px, py)) return [widget];
      widget.child
        ..x = widget.x
        ..y = widget.y;
      if (widget.child.hitTest(localPx, localPy)) {
        final childPath = hitTestPath(widget.child, localPx, localPy);
        if (childPath.isNotEmpty) return childPath;
      }
      return widget.hitTest(px, py) ? [widget] : const [];
    }
    if (!widget.hitTest(px, py)) return const [];
    for (final child in childrenOf(widget).reversed) {
      final childPath = hitTestPath(child, px, py, offX, offY);
      if (childPath.isNotEmpty) return [widget, ...childPath];
    }
    return [widget];
  }

  Widget? hitTest(int px, int py) {
    final path = hitTestPath(root, px, py);
    return path.isEmpty ? null : path.last;
  }

  /// Applies enter/leave callbacks to the complete ancestor path.
  bool updateHover(int px, int py) => setHoverPath(hitTestPath(root, px, py));

  bool setHoverPath(List<Widget> next) {
    var common = 0;
    while (common < _hoverPath.length &&
        common < next.length &&
        identical(_hoverPath[common], next[common])) {
      common++;
    }
    if (common == _hoverPath.length && common == next.length) return false;

    for (var i = _hoverPath.length - 1; i >= common; i--) {
      _hoverPath[i].onMouseLeave?.call();
    }
    for (var i = common; i < next.length; i++) {
      if (next[i].enabled) next[i].onMouseEnter?.call();
    }
    _hoverPath = List<Widget>.of(next);
    return true;
  }

  bool dispatchClick(int px, int py) {
    final path = hitTestPath(root, px, py);
    if (path.any((widget) => !widget.enabled)) return false;
    for (final widget in path.reversed) {
      final handler = widget.onClick;
      if (handler != null && handler()) return true;
    }
    return false;
  }

  /// Routes a pointer press through the shared widget interaction contract.
  ///
  /// Window implementations own surface-specific policies (popup dismissal,
  /// context menus, and painting thresholds), but widget event semantics live
  /// here so xdg and layer-shell surfaces behave identically.
  bool dispatchMouseDown(int px, int py, int button) {
    updateHover(px, py);
    final hit = hitTest(px, py);
    if (hit == null || !hit.enabled) return false;

    _setFocus(hit.isFocusable ? hit : null);
    _dragTarget = hit;
    _pressedButton = button;
    hit.setInteractionState(WidgetState.pressed, true);
    hit.onMouseDown(px, py, button);
    return true;
  }

  /// Routes pointer motion, preserving capture for sliders and other drags.
  bool dispatchMouseMotion(int px, int py) {
    final dragTarget = _dragTarget;
    if (dragTarget != null) {
      dragTarget.onMouseDrag(px, py);
      return true;
    }

    final changed = updateHover(px, py);
    final target = hitTest(px, py);
    target?.onMouseMove(px, py);
    return changed || target != null;
  }

  /// Completes a pointer gesture and emits a click only when the release is
  /// still over the pressed widget.
  bool dispatchMouseUp(int px, int py, int button) {
    final target = _dragTarget;
    final pressedButton = _pressedButton;
    if (target == null) return false;

    target.onMouseUp(px, py, button);
    target.setInteractionState(WidgetState.pressed, false);
    final sameButton = button == pressedButton;
    final stillOverTarget = identical(hitTest(px, py), target);
    if (sameButton && button == 272 && stillOverTarget && target.enabled) {
      dispatchClick(px, py);
    } else if (!stillOverTarget) {
      target.onPointerCancel();
    }

    _dragTarget = null;
    _pressedButton = null;
    return true;
  }

  /// Routes wheel input to the innermost scroll area that can consume it.
  bool dispatchMouseWheel(int px, int py, int dx, int dy) {
    if (dx == 0 && dy == 0) return false;
    final scrollables = <ScrollArea>[];
    _collectScrollAreas(root, px, py, scrollables);
    for (final area in scrollables) {
      area.onSmoothScroll = requestRepaint;
      final beforeX = area.scrollX;
      final beforeY = area.scrollY;
      area.scrollBy(dx.sign * 40, dy.sign * 40);
      if (area.scrollX != beforeX || area.scrollY != beforeY) return true;
    }
    return false;
  }

  /// Routes keyboard input to the focused widget and provides common tab and
  /// activation behavior for windows that do not have their own focus loop.
  bool dispatchKeyPressed(KeyEvent event) {
    if (event.key == 43) return focusNext(reverse: false);
    if (event.key == 44) return focusNext(reverse: true);
    final focused = focus.focusedWidget;
    if (focused == null) return false;
    if (event.key == 28 || event.key == 57) {
      focused.setInteractionState(WidgetState.pressed, true);
    }
    focused.onKeyPressed(event);
    return true;
  }

  bool dispatchKeyReleased(KeyEvent event) {
    final focused = focus.focusedWidget;
    if (focused == null) return false;
    focused.setInteractionState(WidgetState.pressed, false);
    if (event.key == 28 || event.key == 57) focused.activate();
    focused.onKeyReleased(event);
    return true;
  }

  bool focusNext({required bool reverse}) {
    final focusable = <Widget>[];
    _collectFocusable(root, focusable);
    if (focusable.isEmpty) return false;
    focusable.sort((a, b) => a.tabIndex.compareTo(b.tabIndex));
    final current = focus.focusedWidget;
    final index = current == null
        ? (reverse ? 0 : -1)
        : focusable.indexOf(current);
    final next = reverse
        ? (index <= 0 ? focusable.length - 1 : index - 1)
        : (index + 1) % focusable.length;
    _setFocus(focusable[next]);
    return true;
  }

  void clearHover() {
    setHoverPath(const []);
  }

  void requestRepaint() => onRepaint?.call();

  void _setFocus(Widget? next) {
    final old = focus.focusedWidget;
    if (identical(old, next)) return;
    old?.setInteractionState(WidgetState.focused, false);
    old?.onFocusChanged(false);
    focus.focusedWidget = next;
    next?.setInteractionState(WidgetState.focused, true);
    next?.onFocusChanged(true);
  }

  void _collectFocusable(Widget widget, List<Widget> out) {
    if (widget.isFocusable) out.add(widget);
    for (final child in childrenOf(widget)) {
      _collectFocusable(child, out);
    }
  }

  void _collectScrollAreas(
    Widget widget,
    int px,
    int py,
    List<ScrollArea> out,
  ) {
    if (widget is ScrollArea) {
      final localPx = px + widget.scrollX;
      final localPy = py + widget.scrollY;
      if (widget.child.hitTest(localPx, localPy)) {
        _collectScrollAreas(widget.child, localPx, localPy, out);
      }
      if (px >= widget.x &&
          px < widget.x + widget.width &&
          py >= widget.y &&
          py < widget.y + widget.height) {
        out.add(widget);
      }
      return;
    }
    for (final child in childrenOf(widget).reversed) {
      if (child.hitTest(px, py)) {
        _collectScrollAreas(child, px, py, out);
        return;
      }
    }
  }
}
