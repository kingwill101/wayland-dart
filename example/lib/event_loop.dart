import 'dart:async';
import 'dart:collection';
import 'dart:isolate';

import 'mixins/event.dart';
import 'dart:async';
import 'dart:collection';

import 'mixins/event.dart';

class EventLoop {
  final Queue<Event> _eventQueue = Queue<Event>();
  bool _isRunning = false;
  Timer? _timer;

  bool get isRunning => _isRunning;
  int get queueSize => _eventQueue.length;

  void run() {
    if (_isRunning) return;
    _isRunning = true;
    _timer = Timer.periodic(Duration(milliseconds: 16), _processEvents);
  }

  void _processEvents(Timer timer) {
    while (_eventQueue.isNotEmpty) {
      final event = _eventQueue.removeFirst();
      _dispatchEvent(event);
    }
  }

  void _dispatchEvent(Event event) {
    // Implement event dispatching logic here
    print('Processing event: $event');
  }

  void postEvent(Event event) {
    _eventQueue.add(event);
  }

  void stop() {
    _timer?.cancel();
    _isRunning = false;
  }

  static EventLoop? _instance;
  static EventLoop get instance => _instance ??= EventLoop();
}


void dispatch(Event event) {
  EventLoop.instance.postEvent(event);
}
