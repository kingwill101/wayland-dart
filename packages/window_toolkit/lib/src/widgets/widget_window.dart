import '../app.dart';
import '../painter/painter.dart';
import '../mixins/event.dart';
import '../surface_manager.dart';
import '../window.dart';
import '../widget.dart';
import 'align.dart';
import 'card.dart';
import 'context_menu.dart';
import 'flex.dart';
import 'frame.dart';
import 'group_box.dart';
import 'hbox.dart';
import 'layout.dart';
import 'padding.dart';
import 'popup_host.dart';
import 'scroll_area.dart';
import 'tabs.dart';
import 'tooltip.dart';
import 'wrap.dart';

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

class WidgetWindow extends Window {
  /// Minimum window dimensions to prevent layout corruption.
  static const int minWidth = 100;
  static const int minHeight = 60;

  Widget root;
  final FocusModel focus = FocusModel();
  Widget? _lastHovered;
  Widget? _dragTarget;
  bool _dragging = false;
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

  WidgetWindow(this.root);

  @override
  Future<void> show() async {
    if (width < minWidth) width = minWidth;
    if (height < minHeight) height = minHeight;
    await super.show();
    SurfaceManager.init(connection, xdgSurface);
  }

  void requestRedraw() { _redrawPending = true; }

  void flushRedraw() {
    if (_redrawPending) {
      _redrawPending = false;
      if (_canPaint) paint();
    }
  }

  bool get _canPaint => width >= minWidth && height >= minHeight;

  @override
  void draw(Painter painter) {
    // Clamp to minimum so layout doesn't break on tiny windows.
    final w = width < minWidth ? minWidth : width;
    final h = height < minHeight ? minHeight : height;
    root
      ..x = 0
      ..y = 0
      ..width = w
      ..height = h;
    root.performLayout(w);
    root.draw(painter);

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

    final hit = _hitTestRoot(x, y);
    if (hit != _lastHovered) {
      _lastHovered?.onMouseLeave?.call();
      _lastHovered = hit;
      hit?.onMouseEnter?.call();
      if (_canPaint) paint();
    }
  }

  @override
  void onMouseButtonPressed(MouseButtonEvent event) {
    final x = event.x.toInt();
    final y = event.y.toInt();
    final hit = _hitTestRoot(x, y);

    final oldFocus = focus.focusedWidget;
    if (hit != oldFocus) {
      oldFocus?.onMouseLeave?.call();
      focus.focusedWidget = hit;
      hit?.onMouseEnter?.call();
    }

    if (hit != null) {
      _dragTarget = hit;
      _dragging = true;
      hit.onMouseDown(x, y, event.button);
      if (event.button == 272) {
        // Left click — dismiss popups and context menu
        popupHost?.dismiss();
        contextMenu?.hide();
        hit.onClick?.call();
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
      _dragTarget!.onMouseUp(event.x.toInt(), event.y.toInt(), event.button);
    }
    _dragging = false;
    _dragTarget = null;
  }

  @override
  void onMouseWheel(MouseWheelEvent event) {
    final dy = event.dy.round();
    final dx = event.dx.round();
    if (dy == 0 && dx == 0) return;

    // Collect all ScrollAreas from innermost to outermost under the cursor
    final scrollables = <ScrollArea>[];
    _collectScrollAreas(root, event.x.toInt(), event.y.toInt(), 0, 0, scrollables);

    // Wire smooth scroll repaint for any ScrollArea that needs it
    for (final sa in scrollables) {
      sa.onSmoothScroll = () { if (_canPaint) paint(); };
    }

    // Try each one: if a scroll actually changes position, stop
    for (final sa in scrollables) {
      final before = sa.scrollY;
      sa.scrollBy(dx > 0 ? 40 : dx < 0 ? -40 : 0, dy > 0 ? 40 : dy < 0 ? -40 : 0);
      if (sa.scrollY != before) break;
    }
    paint();
  }

  /// Collect all ScrollAreas along the path from [w] to the deepest hit
  /// at (px, py), in innermost-first order.
  void _collectScrollAreas(Widget w, int px, int py, int offX, int offY, List<ScrollArea> out) {
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
    if (event.key == 41) {
      Application.instance.quit();
      return;
    }
    final focused = focus.focusedWidget;
    if (focused != null) {
      focused.onKeyPressed(event);
    }
  }



  /// Find the deepest widget at (px,py) by walking the widget tree.
  /// Handles scroll offsets from ancestor ScrollAreas via [offX]/[offY].
  Widget? _hitTestDeep(Widget w, int px, int py, [int offX = 0, int offY = 0]) {
    if (w is ScrollArea) {
      final localPx = px + w.scrollX + offX;
      final localPy = py + w.scrollY + offY;
      if (w.isOnScrollbar(px, py)) return w;
      // Ensure child is positioned for hit-test, matching ScrollArea.hitTest.
      w.child
        ..x = w.x
        ..y = w.y;
      if (w.child.hitTest(localPx, localPy)) {
        return _hitTestDeep(w.child, localPx, localPy, 0, 0) ?? w;
      }
      return w.hitTest(px, py) ? w : null;
    }
    if (!w.hitTest(px, py)) return null;
    final children = w.children;
    for (final child in children.reversed) {
      final result = _hitTestDeep(child, px, py, offX, offY);
      if (result != null) return result;
    }
    return w;
  }

  Widget? _hitTestRoot(int px, int py) {
    return _hitTestDeep(root, px, py);
  }
}
