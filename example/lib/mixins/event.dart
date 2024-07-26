import 'package:example/modifier_keys.dart';

class Event {
  bool accepted = false;
  bool rejected = false;

  accept() {}

  reject() {}
}

typedef EventCallback<BaseEvent> = void Function(BaseEvent event);

const String kKeyPressed = 'keyPressed';
const String kKeyReleased = 'keyReleased';
const String kMouseEnter = 'MouseEnter';
const String kMouseLeave = 'MouseLeave';
const String kMouseMotion = 'MouseMotion';
const String kMouseButtonPressed = 'MouseButtonPressed';
const String kMouseButtonReleased = 'MouseButtonReleased';

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

  void dispatchEvent(String eventType, Event event) {
    if (_eventListeners[eventType] != null) {
      for (var callback in _eventListeners[eventType]!) {
        callback(event);
      }
    }
  }
}

class KeyEvent extends Event {
  final int key;
  final bool isPressed;
  final ModifierState modifiers;

  KeyEvent(this.key, this.isPressed, this.modifiers);
}

class MouseEvent extends Event {
  final double x;
  final double y;

  MouseEvent(this.x, this.y);
}

class MouseButtonEvent extends MouseEvent {
  final int button;
  final bool isPressed;

  MouseButtonEvent(super.x, super.y, this.button, this.isPressed);
}

class MouseMotionEvent extends MouseEvent {
  MouseMotionEvent(super.x, super.y);
}

class MouseEnterEvent extends MouseEvent {
  MouseEnterEvent(super.x, super.y);
}

class MouseLeaveEvent extends MouseEvent {
  MouseLeaveEvent(super.x, super.y);
}

class PaintEvent extends Event {}
