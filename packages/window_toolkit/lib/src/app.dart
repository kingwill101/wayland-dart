import 'dart:async' as async;
import 'backend/backend.dart';
import 'backend/connection.dart';
import 'event_loop.dart';
import 'mixins/event.dart';

mixin EventReceiver {
  void onEvent(Event event) {}
}

class Application {
  static Application? _instance;

  static Application get instance => _instance ??= Application._internal();

  final List<EventReceiver> _eventReceivers = [];
  final List<Backend> _backends = [];
  final WaylandConnection connection = WaylandConnection();
  bool _running = false;

  Application._internal();

  void addBackend(Backend backend) {
    _backends.add(backend);
  }

  void removeBackend(Backend backend) {
    _backends.remove(backend);
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
    for (final receiver in List<EventReceiver>.from(_eventReceivers)) {
      receiver.onEvent(event);
      if (event.accepted) break;
    }
  }

  /// Insert [receiver] so it sees events before existing receivers (e.g. popups).
  void prependEventReceiver(EventReceiver receiver) {
    _eventReceivers.insert(0, receiver);
  }

  void _execTick() {
    if (!_running) return;

    if (connection.isConnected) {
      // Block up to 16ms waiting for Wayland events. This is a kernel
      // poll() syscall — it naturally survives VM service pauses (CPU
      // profiler, heap snapshot) because the thread is blocked at the OS
      // level. When the VM resumes, poll() returns and we process events.
      connection.dispatchTimeout(16);
      // If the Wayland socket died, stop running.
      if (connection.isConnected && !connection.context.isConnected) {
        _running = false;
        return;
      }
    }
    for (var backend in _backends) {
      if (!backend.isRunning) {
        _running = false;
        return;
      }
    }

    final nextTimer = EventLoop.instance.processOnce();

    if (_running) {
      if (nextTimer > Duration.zero) {
        async.Timer(nextTimer, _execTick);
      } else {
        // Small yield to let the event loop process VM service requests.
        // Without this, the tight poll() loop can starve the VM service.
        async.Timer(const Duration(milliseconds: 1), _execTick);
      }
    }
  }

  void exec() {
    _running = true;
    EventLoop.instance.run();
    _execTick();
  }

  void quit() {
    _running = false;
    EventLoop.instance.stop();
  }

  void reset() {
    _eventReceivers.clear();
    _backends.clear();
    _running = false;
    connection.reset();
    EventLoop.instance.reset();
  }
}
