import '../layer_window.dart';
import '../mixins/event.dart';
import '../widget.dart';
import '../widget_host.dart';

/// Layer-shell window with the same widget host used by [WidgetWindow].
///
/// Layer positioning and surface configuration still belong to
/// [LayerWindow]. This class only adds the shared widget lifecycle and
/// pointer/hover routing. A specialized bar may keep its own module click
/// policy while calling `super` for widget interaction.
class WidgetLayerWindow extends LayerWindow {
  WidgetHostController? _widgetHost;

  WidgetLayerWindow({
    super.anchor,
    super.barHeight,
    super.exclusiveZone,
    super.namespace,
  });

  WidgetHostController get widgetHost {
    final host = _widgetHost;
    if (host == null) {
      throw StateError('attachWidgetRoot must be called before using widgets');
    }
    return host;
  }

  /// Attaches the root after the layer window has been constructed.
  ///
  /// This delayed attachment lets bars build their module tree in the
  /// constructor while the layer backend remains responsible for creating
  /// the Wayland surface.
  void attachWidgetRoot(ElementWidget root, {VoidCallback? onRepaint}) {
    _widgetHost = WidgetHostController(root, onRepaint: onRepaint ?? paint);
  }

  void layoutWidgetRoot(int width, int height) {
    _widgetHost?.layoutRoot(width, height);
  }

  @override
  void onMouseEnter(MouseEnterEvent event) {
    final host = _widgetHost;
    if (host == null) return;
    if (host.updateHover(event.x.toInt(), event.y.toInt())) {
      host.requestRepaint();
    }
  }

  @override
  void onMouseMotion(MouseMotionEvent event) {
    final host = _widgetHost;
    if (host == null) return;
    // Do not repaint for every pointer sample while the pointer remains over
    // the same widget. Widget motion handlers request their own repaint when
    // a drag/segment state actually changes.
    if (host.dispatchMouseMotion(event.x.toInt(), event.y.toInt())) {
      host.requestRepaint();
    }
  }

  @override
  void onMouseButtonPressed(MouseButtonEvent event) {
    final host = _widgetHost;
    if (host == null) return;
    if (host.dispatchMouseDown(
      event.x.toInt(),
      event.y.toInt(),
      event.button,
    )) {
      host.requestRepaint();
    }
  }

  @override
  void onMouseButtonReleased(MouseButtonEvent event) {
    final host = _widgetHost;
    if (host == null) return;
    if (host.dispatchMouseUp(event.x.toInt(), event.y.toInt(), event.button)) {
      host.requestRepaint();
    }
  }

  @override
  void onMouseWheel(MouseWheelEvent event) {
    final host = _widgetHost;
    if (host == null) return;
    if (host.dispatchMouseWheel(
      event.x.toInt(),
      event.y.toInt(),
      event.dx.round(),
      event.dy.round(),
    )) {
      host.requestRepaint();
    }
  }

  @override
  void onKeyPressed(KeyEvent event) {
    final host = _widgetHost;
    if (host == null) return;
    if (host.dispatchKeyPressed(event)) host.requestRepaint();
  }

  @override
  void onKeyReleased(KeyEvent event) {
    final host = _widgetHost;
    if (host == null) return;
    if (host.dispatchKeyReleased(event)) host.requestRepaint();
  }

  @override
  void onMouseLeave(MouseLeaveEvent event) {
    final host = _widgetHost;
    if (host == null) return;
    host.clearHover();
    host.requestRepaint();
  }
}
