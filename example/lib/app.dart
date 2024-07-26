import 'package:example/event_loop.dart';
import 'package:example/mixins/event.dart';

mixin EventReceiver {
  void onEvent(Event event) {}
}

// class WaylandBackend{}

class Application {
  static Application? _instance;

  static Application get instance => _instance ??= Application._internal();

  // late final Wayland _waylandBackend;
  final List<EventReceiver> _eventReceivers = [];

  Application._internal() {
    EventLoop.instance.run();
  }

  void run() {
    EventLoop.instance.run();
    while (EventLoop.instance.isRunning) {
      print("");
    }
  }

  void addEventReceiver(EventReceiver receiver) {
    _eventReceivers.add(receiver);
  }

  void removeEventReceiver(EventReceiver receiver) {
    _eventReceivers.remove(receiver);
  }

  void postEvent(Event event) {
    EventLoop.instance.postEvent(event);
  }

  void dispatchEvent(Event event) {
    for (var receiver in _eventReceivers) {
      receiver.onEvent(event);
    }
  }

  void quit() {
    EventLoop.instance.stop();
  }
}
