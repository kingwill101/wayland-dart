import 'app.dart';
import 'backend/wayland.dart';
import 'window_behavior.dart';

class Window extends WaylandBackend with EventReceiver, WindowBehavior {
  Window() {
    initWindow();
  }
}
