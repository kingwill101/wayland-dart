import '../painter/painter.dart';
import '../widget.dart';
import 'connection.dart';

abstract class Backend {
  bool get isRunning;
  int get width;
  int get height;
  set width(int value);
  set height(int value);
  void Function(int width, int height)? get onConfigure;
  set onConfigure(void Function(int width, int height)? callback);
  Function()? get onClose;
  set onClose(Function()? callback);

  WaylandConnection get connection;

  void dispatchEvents();
  void destroy();
  Future<void> init();
  void start();
  Painter createPainter(int width, int height);
  void paintWithPainter(Painter painter);

  /// Whether the backend is ready to accept a new frame.
  /// Returns false when the previous buffer is still busy.
  bool get canPaint => true;

  /// Requests a repaint on the next available opportunity.
  void requestPaint() {}

  /// Called by the backend when a previously-busy buffer becomes available
  /// and a repaint was requested. The window should issue a new paint().
  VoidCallback? onFrameReady;
}
