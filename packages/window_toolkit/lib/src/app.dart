import 'dart:async' as async;
import 'backend/backend.dart';
import 'event_loop.dart';
import 'mixins/event.dart';
import 'platform/platform.dart';

mixin EventReceiver {
  void onEvent(Event event) {}
}

class Application {
  static Application? _instance;

  static Application get instance => _instance ??= Application._internal();

  final List<EventReceiver> _eventReceivers = [];
  final List<Backend> _backends = [];
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

    final connections = <PlatformConnection>{
      for (final backend in _backends) backend.platformConnection,
    };
    for (final connection in connections) {
      if (!connection.isConnected) continue;
      // Use scheduleMicrotask to re-dispatch immediately — this ensures
      // platform polling happens BEFORE any VM service event processing.
      // async.Timer.run posts to the event loop, which lets VM service
      // messages (profiler data) queue between iterations and delay the
      // next poll, causing the compositor to disconnect.
      connection.dispatch();
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
        async.Timer(nextTimer, () => _execTick());
      } else {
        // Schedule as microtask — runs before any event loop events.
        async.scheduleMicrotask(() => _execTick());
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
    final connections = <PlatformConnection>{
      for (final backend in _backends) backend.platformConnection,
    };
    for (final connection in connections) {
      connection.reset();
    }
    _eventReceivers.clear();
    _backends.clear();
    _running = false;
    EventLoop.instance.reset();
  }
}
