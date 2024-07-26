
import 'mixins/event.dart';

export 'mixins/event.dart';

abstract class BaseWidget with Events {
  void onKeyPressed(KeyEvent event) {}
  void onKeyReleased(KeyEvent event) {}
  void onMouseEnter(MouseEnterEvent event) {}
  void onMouseLeave(MouseLeaveEvent event) {}
  void onMouseMotion(MouseMotionEvent event) {}
  void onMouseButtonPressed(MouseButtonEvent event) {}
  void onMouseButtonReleased(MouseButtonEvent event) {}

  @override
  void dispatchEvent(String eventType, Event event) {
    super.dispatchEvent(eventType, event);

    if (eventType == kKeyPressed) {
      onKeyPressed(event as KeyEvent);
    } else if (eventType == kKeyReleased) {
      onKeyReleased(event as KeyEvent);
    } else if (eventType == kMouseEnter) {
      onMouseEnter(event as MouseEnterEvent);
    } else if (eventType == kMouseLeave) {
      onMouseLeave(event as MouseLeaveEvent);
    } else if (eventType == kMouseMotion) {
      onMouseMotion(event as MouseMotionEvent);
    } else if (eventType == kMouseButtonPressed) {
      onMouseButtonPressed(event as MouseButtonEvent);
    } else if (eventType == kMouseButtonReleased) {
      onMouseButtonReleased(event as MouseButtonEvent);
    }
  }
}
