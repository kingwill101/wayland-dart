import 'package:wayland/wayland.dart';

import 'backend/connection.dart';
import 'backend/popup.dart';
import 'widget.dart';
import 'widgets/card.dart';
import 'widgets/label.dart';
import 'widgets/popup_window.dart';

/// Provides access to the active Wayland session for any widget in the tree.
/// Widgets call [SurfaceManager.instance] to create popups, tooltips, etc.
class SurfaceManager {
  static SurfaceManager? _instance;

  /// The connected Wayland session. Set by [WidgetWindow] on show().
  static SurfaceManager? get instance => _instance;

  /// Initialise with a valid connection + parent surface.
  /// Called automatically by [WidgetWindow.show].
  static void init(WaylandConnection conn, XdgSurface parent) {
    _instance ??= SurfaceManager._(conn, parent);
  }

  /// Clear the instance (for testing / cleanup).
  static void reset() => _instance = null;

  final WaylandConnection connection;
  final XdgSurface parentSurface;

  SurfaceManager._(this.connection, this.parentSurface);

  /// Open an xdg-popup with the given [content] widget tree.
  PopupWindow showPopup({
    required Widget content,
    int width = 200,
    int height = 200,
    int anchorX = 0,
    int anchorY = 0,
    int anchorWidth = 0,
    int anchorHeight = 0,
  }) {
    final backend = PopupBackend(
      connection: connection,
      parentSurface: parentSurface,
      width: width,
      height: height,
      anchorX: anchorX,
      anchorY: anchorY,
      anchorWidth: anchorWidth,
      anchorHeight: anchorHeight,
    );
    final pw = PopupWindow(backend: backend, root: content);
    backend.onDismiss = pw.close;
    pw.show();
    return pw;
  }

  /// Convenience: open a tooltip popup near (anchorX, anchorY).
  PopupWindow showTooltip(String text, int anchorX, int anchorY) {
    final label = Label(text)
      ..x = 8
      ..y = 8
      ..width = text.length * 8
      ..height = 16;
    label.width = text.length * 8;
    label.height = 16;
    final contentW = label.width + 16;
    final contentH = label.height + 16;
    final card = Card(children: [label]);
    card.width = contentW;
    card.height = contentH;
    return showPopup(
      content: card,
      width: contentW,
      height: contentH,
      anchorX: anchorX,
      anchorY: anchorY + 10,
    );
  }
}
