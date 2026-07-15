import 'package:wayland/wayland.dart';

import '../backend/connection.dart';
import '../widget.dart';
import 'popup_window.dart';

/// A helper that lets a [WidgetWindow] open real xdg-popup surfaces
/// for menus, dropdowns, tooltips, and dialogs.
class PopupHost {
  final WaylandConnection connection;
  final XdgSurface parentSurface;
  PopupWindow? _active;

  PopupHost({
    required this.connection,
    required this.parentSurface,
  });

  bool get hasActivePopup => _active != null && _active!.visible;

  /// Opens a popup at the given anchor rect (in window-local coords).
  /// [content] is drawn inside the popup surface.
  PopupWindow show({
    required Widget content,
    int width = 200,
    int height = 200,
    int anchorX = 0,
    int anchorY = 0,
    int anchorWidth = 0,
    int anchorHeight = 0,
  }) {
    dismiss();
    final pw = PopupWindow.create(
      connection: connection,
      parentSurface: parentSurface,
      content: content,
      width: width,
      height: height,
      anchorX: anchorX,
      anchorY: anchorY,
      anchorWidth: anchorWidth,
      anchorHeight: anchorHeight,
    );
    pw.backend.onDismiss = dismiss;
    pw.show();
    _active = pw;
    return pw;
  }

  /// Closes the active popup.
  void dismiss() {
    _active?.close();
    _active = null;
  }
}
