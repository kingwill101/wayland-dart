/// Animation controller driven by [EventLoop] timers.
library;

import '../event_loop.dart' as el;
import 'animation.dart';
import 'curves.dart';
import 'tween.dart';

/// Drives an animation from 0.0 to 1.0 (or reverse) over [duration].
///
/// Uses [el.EventLoop.addTimer] to schedule frames at ~60fps.
/// Each tick updates [value] and notifies listeners.
///
/// ```dart
/// final controller = AnimationController(duration: Duration(milliseconds: 300));
/// controller.addListener(() => widgetWindow.requestRedraw());
/// controller.forward();
/// ```
class AnimationController extends Animation<double> {
  final Duration duration;
  final Curve curve;

  AnimationController({
    this.duration = const Duration(milliseconds: 200),
    this.curve = linear,
  }) {
    _updateValue(0.0, AnimationStatus.dismissed);
  }

  double _value = 0.0;
  AnimationStatus _status = AnimationStatus.dismissed;
  DateTime _startTime = DateTime.now();
  int _direction = 1; // 1 = forward, -1 = reverse
  el.Timer? _timer;
  bool _active = true;

  @override
  double get value => _value;

  @override
  AnimationStatus get status => _status;

  bool get isAnimating => _timer != null && _timer!.isActive;

  void _updateValue(double v, AnimationStatus s) {
    _value = v;
    if (s != _status) {
      final old = _status;
      _status = s;
      if (s != old) notifyStatusListeners(s);
    }
    notifyListeners();
  }

  void _scheduleNextFrame() {
    _timer?.cancel();
    _timer = el.EventLoop.instance.addTimer(
      const Duration(milliseconds: 16), // ~60fps
      _tick,
    );
  }

  void _tick() {
    if (!isAnimating) return;

    final elapsed = DateTime.now().difference(_startTime);
    final t = (elapsed.inMicroseconds / duration.inMicroseconds).clamp(0.0, 1.0);

    final curved = curve.transform(t);
    final v = _direction == 1 ? curved : 1.0 - curved;

    if (t >= 1.0) {
      _timer?.cancel();
      _timer = null;
      _updateValue(v, AnimationStatus.completed);
      return;
    }

    _updateValue(v, AnimationStatus.forward);
    _scheduleNextFrame();
  }

  /// Start the animation from current value toward 1.0.
  void forward({double? from}) {
    _active = true;
    _direction = 1;
    _startTime = DateTime.now();
    if (from != null) _updateValue(from, AnimationStatus.forward);
    _scheduleNextFrame();
  }

  /// Start the animation from current value toward 0.0.
  void reverse({double? from}) {
    _active = true;
    _direction = -1;
    _startTime = DateTime.now();
    if (from != null) _updateValue(from, AnimationStatus.reverse);
    _scheduleNextFrame();
  }

  /// Animate to a specific [target] value over [duration].
  void animateTo(double target, {Duration? duration}) {
    // Simple implementation: set target and run forward/reverse.
    if (target > _value) {
      _direction = 1;
    } else {
      _direction = -1;
    }
    _startTime = DateTime.now();
    _scheduleNextFrame();
  }

  /// Repeat the animation continuously.
  void repeat({bool reverse = false, double? from}) {
    // TODO: implement full repeat with reverse
    forward(from: from);
  }

  /// Stop the animation at the current value.
  void stop() {
    _timer?.cancel();
    _timer = null;
    _active = false;
  }

  /// Reset to 0.0 without animation.
  void reset() {
    stop();
    _active = true;
    _updateValue(0.0, AnimationStatus.dismissed);
  }

  /// Advance the animation by [elapsed] time (for testing without EventLoop).
  /// Returns the new value after advancing. No-op when stopped or disposed.
  double tick(Duration elapsed) {
    if (!_active) return value;
    final t = (elapsed.inMicroseconds / duration.inMicroseconds).clamp(0.0, 1.0);
    final curved = curve.transform(t);
    final v = _direction == 1 ? curved : 1.0 - curved;

    if (t >= 1.0) {
      _updateValue(v, AnimationStatus.completed);
    } else {
      _updateValue(v, _direction == 1 ? AnimationStatus.forward : AnimationStatus.reverse);
    }
    return value;
  }

  /// Dispose of the controller, releasing timer resources.
  void dispose() {
    stop();
  }
}

/// A [Tween] that drives itself via an [AnimationController].
class TweenAnimation<T extends num> extends Tween<T> {
  final AnimationController controller;

  TweenAnimation({
    required T begin,
    required T end,
    Duration duration = const Duration(milliseconds: 200),
    Curve curve = linear,
  })  : controller = AnimationController(duration: duration, curve: curve),
        super(begin: begin, end: end) {
    animate(controller);
  }

  void forward() => controller.forward();
  void reverse() => controller.reverse();
  void dispose() => controller.dispose();
}
