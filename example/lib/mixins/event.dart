class BaseEvent {}

typedef EventCallback<BaseEvent> = void Function(BaseEvent event);

const String kKeyPressed = 'keyPressed';
const String kKeyReleased = 'keyReleased';

mixin Events {
  final Map<String, List<EventCallback>> _eventListeners = {};

  void on(String eventType, EventCallback callback) {
    if (_eventListeners[eventType] == null) {
      _eventListeners[eventType] = [];
    }
    _eventListeners[eventType]!.add(callback);
  }

  void off(String eventType, EventCallback callback) {
    _eventListeners[eventType]?.remove(callback);
  }

  void dispatchEvent(String eventType, BaseEvent event) {
    if (_eventListeners[eventType] != null) {
      for (var callback in _eventListeners[eventType]!) {
        callback(event);
      }
    }
  }
}

class KeyEvent extends BaseEvent {
  final int key;
  final bool isPressed;

  KeyEvent(this.key, this.isPressed);
}
