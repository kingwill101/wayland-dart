import 'mixins/event.dart';

export 'mixins/event.dart';

abstract class BaseWidget with Events {
  void onKeyPressed(KeyEvent event) {}

  void onKeyReleased(KeyEvent event) {}

  @override
  void dispatchEvent(String eventType, BaseEvent event) {
    super.dispatchEvent(eventType, event);
    if (eventType == kKeyPressed) {
      onKeyPressed(event as KeyEvent);
    } else if (eventType == kKeyReleased) {
      onKeyReleased(event as KeyEvent);
    }
  }
}
