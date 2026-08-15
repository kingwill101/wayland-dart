import '../app.dart';
import '../painter/painter.dart';
import '../mixins/event.dart';
import '../interaction.dart';
import '../surface_manager.dart';
import '../window.dart';
import '../widget.dart';
import '../widget_children.dart';
import '../widget_host.dart';
import 'context_menu.dart';
import 'popup_host.dart';
import 'scroll_area.dart';

class WidgetWindow extends Window {
  /// Minimum window dimensions to prevent layout corruption.
  static const int minWidth = 100;
  static const int minHeight = 60;

  late final WidgetHostController widgetHost;
  Widget? _dragTarget;
  bool _dragging = false;
  int? _pressedButton;
  bool _redrawPending = false;
  ContextMenu? contextMenu;

  /// Host for real xdg-popup surfaces (menus, dropdowns, dialogs).
  /// Created lazily when first needed; requires a live Wayland session.
  PopupHost? _popupHost;
  PopupHost? get popupHost {
    if (_popupHost == null && connection.isConnected) {
      try {
        _popupHost = PopupHost(
          connection: connection,
          parentSurface: xdgSurface,
        );
      } catch (_) {}
    }
    return _popupHost;
  }

  /// Optional Element tree for StatefulWidget/StatelessWidget management.
  ElementTree? get elementTree => widgetHost.elementTree;
  Widget get root => widgetHost.root;
  FocusModel get focus => widgetHost.focus;

  WidgetWindow(ElementWidget rootWidget) {
    widgetHost = WidgetHostController(rootWidget, onRepaint: requestRedraw);
  }

  @override
  Future<void> show() async {
    if (width < minWidth) width = minWidth;
    if (height < minHeight) height = minHeight;
    await super.show();
    SurfaceManager.init(connection, xdgSurface);
  }

  void requestRedraw() {
    _redrawPending = true;
  }

  void flushRedraw() {
    if (_redrawPending) {
      _redrawPending = false;
      if (_canPaint) paint();
    }
  }

  bool get _canPaint => width >= minWidth && height >= minHeight;

  @override
  void draw(Painter painter) {
    final w = width < minWidth ? minWidth : width;
    final h = height < minHeight ? minHeight : height;

    widgetHost.draw(painter, width: w, height: h);

    if (contextMenu != null && contextMenu!.visible) {
      contextMenu!.draw(painter);
    }
  }

  @override
  void onMouseMotion(MouseMotionEvent event) {
    final x = event.x.toInt();
    final y = event.y.toInt();

    if (_dragging && _dragTarget != null) {
      _dragTarget!.onMouseDrag(x, y);
      if (_canPaint) paint();
      return;
    }

    if (_updateHoverPath(x, y)) {
      if (_canPaint) paint();
    }
    final motionTarget = _hitTestRoot(x, y);
    motionTarget?.onMouseMove(x, y);
    if (motionTarget != null && _canPaint) paint();
  }

  @override
  void onMouseLeave(MouseLeaveEvent event) {
    if (_setHoverPath(const [])) {
      if (_canPaint) paint();
    }
  }

  @override
  void onMouseButtonPressed(MouseButtonEvent event) {
    final x = event.x.toInt();
    final y = event.y.toInt();
    _updateHoverPath(x, y);
    final hit = _hitTestRoot(x, y);

    final oldFocus = focus.focusedWidget;
    final nextFocus = hit?.enabled == true && hit?.isFocusable == true
        ? hit
        : null;
    if (nextFocus != oldFocus) {
      oldFocus?.setInteractionState(WidgetState.focused, false);
      oldFocus?.onFocusChanged(false);
      focus.focusedWidget = nextFocus;
      nextFocus?.setInteractionState(WidgetState.focused, true);
      nextFocus?.onFocusChanged(true);
    }

    if (hit != null && hit.enabled) {
      _dragTarget = hit;
      _dragging = true;
      _pressedButton = event.button;
      hit.setInteractionState(WidgetState.pressed, true);
      hit.onMouseDown(x, y, event.button);
      if (event.button == 272) {
        // Left click dismisses popups after the control receives activation.
      } else {
        // Right click — show context menu at cursor
        contextMenu?.show(x, y);
        requestRedraw();
      }
    }
    if (_canPaint) paint();
  }

  @override
  void onMouseButtonReleased(MouseButtonEvent event) {
    if (_dragging && _dragTarget != null) {
      final target = _dragTarget!;
      target.onMouseUp(event.x.toInt(), event.y.toInt(), event.button);
      target.setInteractionState(WidgetState.pressed, false);
      if (event.button == _pressedButton && event.button == 272) {
        final hit = _hitTestRoot(event.x.toInt(), event.y.toInt());
        if (identical(hit, target) && target.enabled) {
          popupHost?.dismiss();
          contextMenu?.hide();
          _dispatchClick(event.x.toInt(), event.y.toInt());
        } else {
          target.onPointerCancel();
        }
      }
    }
    _dragging = false;
    _dragTarget = null;
    _pressedButton = null;
    if (_canPaint) paint();
  }

  @override
  void onMouseWheel(MouseWheelEvent event) {
    final dy = event.dy.round();
    final dx = event.dx.round();
    if (dy == 0 && dx == 0) return;

    // Collect all ScrollAreas from innermost to outermost under the cursor
    final scrollables = <ScrollArea>[];
    _collectScrollAreas(
      root,
      event.x.toInt(),
      event.y.toInt(),
      0,
      0,
      scrollables,
    );

    // Wire smooth scroll repaint for any ScrollArea that needs it
    for (final sa in scrollables) {
      sa.onSmoothScroll = () {
        if (_canPaint) paint();
      };
    }

    // Try each one: if a scroll actually changes position, stop
    for (final sa in scrollables) {
      final before = sa.scrollY;
      sa.scrollBy(
        dx > 0
            ? 40
            : dx < 0
            ? -40
            : 0,
        dy > 0
            ? 40
            : dy < 0
            ? -40
            : 0,
      );
      if (sa.scrollY != before) break;
    }
    paint();
  }

  /// Collect all ScrollAreas along the path from [w] to the deepest hit
  /// at (px, py), in innermost-first order.
  void _collectScrollAreas(
    Widget w,
    int px,
    int py,
    int offX,
    int offY,
    List<ScrollArea> out,
  ) {
    if (w is ScrollArea) {
      final localPx = px + w.scrollX + offX;
      final localPy = py + w.scrollY + offY;
      if (w.child.hitTest(localPx, localPy)) {
        _collectScrollAreas(w.child, localPx, localPy, 0, 0, out);
      }
      // Add this ScrollArea if the raw point is within its bounds.
      // We use hitTest on the child only for nesting; the ScrollArea
      // itself should scroll even when the cursor is in empty space
      // between children.
      if (px >= w.x && px < w.x + w.width && py >= w.y && py < w.y + w.height) {
        out.add(w);
      }
      return;
    }

    final children = w.children;
    for (final child in children.reversed) {
      if (child.hitTest(px, py)) {
        _collectScrollAreas(child, px, py, offX, offY, out);
        return; // only follow the deepest path
      }
    }
  }

  @override
  void onKeyPressed(KeyEvent event) {
    // Escape to quit.
    if (event.key == 41) {
      Application.instance.quit();
      return;
    }
    // Tab / Shift+Tab for focus cycling.
    if (event.key == 43) {
      _focusNext();
      return;
    }
    if (event.key == 44) {
      _focusPrevious();
      return;
    }
    final focused = focus.focusedWidget;
    if (focused != null) {
      if (event.key == 28 || event.key == 57) {
        focused.setInteractionState(WidgetState.pressed, true);
      }
      focused.onKeyPressed(event);
    }
  }

  @override
  void onKeyReleased(KeyEvent event) {
    final focused = focus.focusedWidget;
    if (focused == null) return;
    focused.setInteractionState(WidgetState.pressed, false);
    if (event.key == 28 || event.key == 57) {
      focused.activate();
    }
    focused.onKeyReleased(event);
    if (_canPaint) paint();
  }

  /// Move focus to the next focusable widget (Tab order).
  void _focusNext() {
    // Use element tree focus navigation when available.
    if (elementTree?.root != null) {
      _syncElementFocusability(elementTree!.root!);
      final currentEl = _currentFocusElement();
      final next = Element.findNextFocus(
        elementTree!.root!,
        current: currentEl,
      );
      if (next != null) _setFocusElement(next);
      return;
    }
    // Legacy widget-based focus.
    final all = <Widget>[];
    _collectFocusable(root, all);
    if (all.isEmpty) return;
    all.sort((a, b) => a.tabIndex.compareTo(b.tabIndex));
    final current = focus.focusedWidget;
    final idx = current == null ? -1 : all.indexOf(current);
    final next = (idx + 1) % all.length;
    _setFocus(all[next]);
  }

  void _focusPrevious() {
    if (elementTree?.root != null) {
      _syncElementFocusability(elementTree!.root!);
      final currentEl = _currentFocusElement();
      final prev = Element.findPreviousFocus(
        elementTree!.root!,
        current: currentEl,
      );
      if (prev != null) _setFocusElement(prev);
      return;
    }
    final all = <Widget>[];
    _collectFocusable(root, all);
    if (all.isEmpty) return;
    all.sort((a, b) => a.tabIndex.compareTo(b.tabIndex));
    final current = focus.focusedWidget;
    final idx = current == null ? 0 : all.indexOf(current);
    final prev = (idx - 1 + all.length) % all.length;
    _setFocus(all[prev]);
  }

  void _setFocus(Widget w) {
    final old = focus.focusedWidget;
    if (old == w) return;
    old?.setInteractionState(WidgetState.focused, false);
    old?.onFocusChanged(false);
    focus.focusedWidget = w;
    w.setInteractionState(WidgetState.focused, true);
    w.onFocusChanged(true);
    if (_canPaint) paint();
  }

  void _setFocusElement(Element el) {
    _syncElementFocusability(el);
    if (el.widget is Widget) {
      _setFocus(el.widget as Widget);
    }
  }

  /// Find the element whose widget is the currently focused widget.
  Element? _currentFocusElement() {
    final focused = focus.focusedWidget;
    if (focused == null || elementTree?.root == null) return null;
    Element? find(Element e) {
      if (identical(e.widget, focused) || identical(e.renderWidget, focused))
        return e;
      for (final c in e.children) {
        final r = find(c);
        if (r != null) return r;
      }
      return null;
    }

    return find(elementTree!.root!);
  }

  /// Sync focusability from widgets to their elements.
  void _syncElementFocusability(Element el) {
    el.focusable = el.widget is Widget && (el.widget as Widget).isFocusable;
    for (final c in el.children) {
      _syncElementFocusability(c);
    }
  }

  void _collectFocusable(Widget w, List<Widget> out) {
    if (w.isFocusable) out.add(w);
    for (final child in childrenOf(w)) {
      _collectFocusable(child, out);
    }
  }

  /// Collect hit-test ancestor path at (px,py), deepest widget first.
  /// Uses widget-tree traversal (not element tree) because ScrollArea's
  /// scroll offset adjustments aren't reflected in element bounds.
  /// The generic [Element.hitTest] in layout_engine provides a
  /// framework-agnostic alternative for trees without scroll containers.
  List<Widget> _hitTestPath(
    Widget w,
    int px,
    int py, [
    int offX = 0,
    int offY = 0,
  ]) {
    return widgetHost.hitTestPath(w, px, py, offX, offY);
  }

  /// Bubbles [onClick] through the ancestor path at (px,py).
  bool _dispatchClick(int px, int py) {
    return widgetHost.dispatchClick(px, py);
  }

  Widget? _hitTestRoot(int px, int py) {
    final path = _hitTestPath(root, px, py);
    return path.isNotEmpty ? path.last : null;
  }

  /// Applies pointer enter/leave callbacks to the changed ancestor path.
  ///
  /// Keeping the whole path active makes both a parent CSS `:hover` rule and
  /// the deepest button/control state work when widgets are nested.
  bool _updateHoverPath(int px, int py) {
    return _setHoverPath(_hitTestPath(root, px, py));
  }

  bool _setHoverPath(List<Widget> next) {
    return widgetHost.setHoverPath(next);
  }
}
