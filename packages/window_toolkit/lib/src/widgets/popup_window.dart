import 'package:wayland/wayland.dart';

import '../backend/connection.dart';
import '../backend/popup.dart';
import '../drawing/color.dart';
import '../widget.dart';

/// Wraps a [PopupBackend] with a widget tree, providing [show], [close],
/// and [paint] methods for rendering and managing a real xdg-popup surface.
class PopupWindow {
  final PopupBackend backend;
  final Widget root;
  bool _visible = false;

  PopupWindow({required this.backend, required this.root})
    : assert(backend.width > 0, 'PopupWindow backend width must be > 0'),
      assert(backend.height > 0, 'PopupWindow backend height must be > 0');

  bool get visible => _visible;

  void show() {
    _visible = true;
    backend.start();
    paint();
  }

  void close() {
    _visible = false;
    backend.destroy();
  }

  void paint() {
    if (!_visible) return;
    final painter = backend.createPainter(backend.width, backend.height);
    painter.clear(const Color(0, 0, 0));
    root
      ..x = 0
      ..y = 0
      ..width = backend.width
      ..height = backend.height;
    root.draw(painter);
    backend.paintWithPainter(painter);
  }

  /// Factory to build a [PopupWindow] from a [PopupBackend].
  static PopupWindow create({
    required WaylandConnection connection,
    required XdgSurface parentSurface,
    required Widget content,
    int width = 200,
    int height = 300,
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
    return PopupWindow(backend: backend, root: content);
  }
}
