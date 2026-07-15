import 'dart:collection';

import 'mixins/event.dart';

class Timer {
  final Duration interval;
  final void Function() callback;
  bool _active = true;
  DateTime _nextFire;

  Timer(this.interval, this.callback)
      : _nextFire = DateTime.now().add(interval);

  bool get isActive => _active;

  void cancel() => _active = false;

  bool _tick() {
    if (!_active) return false;
    final now = DateTime.now();
    if (now.isAfter(_nextFire)) {
      _nextFire = now.add(interval);
      callback();
      return true;
    }
    return false;
  }
}

class EventLoop {
  final Queue<Event> _eventQueue = Queue<Event>();
  final List<Timer> _timers = [];
  bool _isRunning = false;

  bool get isRunning => _isRunning;
  int get queueSize => _eventQueue.length;

  void run() {
    _isRunning = true;
  }

  Timer addTimer(Duration interval, void Function() callback) {
    final timer = Timer(interval, callback);
    _timers.add(timer);
    return timer;
  }

  void removeTimer(Timer timer) {
    timer.cancel();
    _timers.remove(timer);
  }

  Duration processOnce() {
    while (_eventQueue.isNotEmpty) {
      final event = _eventQueue.removeFirst();
      _dispatchEvent(event);
    }

    // Check timers and find the next fire time
    var minWait = const Duration(milliseconds: 100);
    final now = DateTime.now();

    for (var i = _timers.length - 1; i >= 0; i--) {
      final timer = _timers[i];
      if (!timer.isActive) {
        _timers.removeAt(i);
        continue;
      }
      final wait = timer._nextFire.difference(now);
      if (wait.isNegative) {
        timer._tick();
        minWait = Duration.zero;
      } else if (wait < minWait) {
        minWait = wait;
      }
    }

    return minWait;
  }

  void _dispatchEvent(Event event) {}

  void postEvent(Event event) {
    _eventQueue.add(event);
  }

  void stop() {
    _isRunning = false;
  }

  void reset() {
    _eventQueue.clear();
    _timers.clear();
    _isRunning = false;
  }

  static EventLoop? _instance;
  static EventLoop get instance => _instance ??= EventLoop();
}

void dispatch(Event event) {
  EventLoop.instance.postEvent(event);
}
