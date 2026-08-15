/// Animation controller driven by [EventLoop] timers.
library;

import '../event_loop.dart' as el;
import 'animation.dart';
import 'curves.dart';
import 'animatable.dart';

/// How an [AnimationController] behaves when [repeat] is called.
enum RepeatMode {
  /// Restart from the beginning each time.
  restart,

  /// Alternate between forward and reverse.
  reverse,
}

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
  bool _disposed = false;

  // Repeat state
  bool _isRepeating = false;
  RepeatMode _repeatMode = RepeatMode.restart;
  int _repeatCount = 0; // 0 = infinite when _isRepeating
  int _currentCycle = 0;

  @override
  double get value => _value;

  @override
  AnimationStatus get status => _status;

  bool get isAnimating => _timer != null && _timer!.isActive;

  bool get isDisposed => _disposed;

  void _updateValue(double v, AnimationStatus s) {
    if (_disposed) return;
    _value = v;
    if (s != _status) {
      final old = _status;
      _status = s;
      if (s != old) notifyStatusListeners(s);
    }
    notifyListeners();
  }

  void _scheduleNextFrame() {
    if (_disposed) return;
    _timer?.cancel();
    _timer = el.EventLoop.instance.addTimer(
      const Duration(milliseconds: 16), // ~60fps
      _tick,
    );
  }

  void _tick() {
    if (_disposed || !isAnimating) return;

    final elapsed = DateTime.now().difference(_startTime);
    final t = (elapsed.inMicroseconds / duration.inMicroseconds).clamp(0.0, 1.0);

    final curved = curve.transform(t);
    final v = _direction == 1 ? curved : 1.0 - curved;

    if (t >= 1.0) {
      if (_isRepeating) {
        _currentCycle++;
        // count == 0 means infinite; otherwise repeat `count` total cycles.
        if (_repeatCount > 0 && _currentCycle >= _repeatCount) {
          _timer?.cancel();
          _timer = null;
          _updateValue(v, AnimationStatus.completed);
          return;
        }
        if (_repeatMode == RepeatMode.reverse) {
          _direction *= -1;
        }
        _startTime = DateTime.now();
        _scheduleNextFrame();
        return;
      }

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
    if (_disposed) return;
    _active = true;
    _direction = 1;
    _isRepeating = false;
    _repeatCount = 0;
    _currentCycle = 0;
    _startTime = DateTime.now();
    if (from != null) _updateValue(from, AnimationStatus.forward);
    _scheduleNextFrame();
  }

  /// Start the animation from current value toward 0.0.
  void reverse({double? from}) {
    if (_disposed) return;
    _active = true;
    _direction = -1;
    _isRepeating = false;
    _repeatCount = 0;
    _currentCycle = 0;
    _startTime = DateTime.now();
    if (from != null) _updateValue(from, AnimationStatus.reverse);
    _scheduleNextFrame();
  }

  /// Animate to a specific [target] value over [duration].
  void animateTo(double target, {Duration? duration}) {
    if (_disposed) return;
    _active = true;
    _isRepeating = false;
    _repeatCount = 0;
    _currentCycle = 0;
    _startTime = DateTime.now();
    _scheduleNextFrame();
  }

  /// Repeat the animation continuously.
  void repeat({int count = 0, RepeatMode mode = RepeatMode.restart, double? from}) {
    if (_disposed) return;
    _active = true;
    _direction = 1;
    _isRepeating = true;
    _repeatMode = mode;
    _repeatCount = count;
    _currentCycle = 0;
    _startTime = DateTime.now();
    if (from != null) _updateValue(from, AnimationStatus.forward);
    _scheduleNextFrame();
  }

  /// Stop the animation at the current value.
  void stop() {
    _timer?.cancel();
    _timer = null;
    _active = false;
  }

  /// Reset to 0.0 without animation.
  void reset() {
    if (_disposed) return;
    stop();
    _active = true;
    _updateValue(0.0, AnimationStatus.dismissed);
  }

  /// Drive an [Animatable<T>] from this controller's value.
  Animation<T> drive<T>(Animatable<T> animatable) {
    return animatable.animate(this);
  }

  /// Advance the animation by [elapsed] time (for testing without EventLoop).
  double tick(Duration elapsed) {
    if (!_active || _disposed) return value;

    final t = (elapsed.inMicroseconds / duration.inMicroseconds).clamp(0.0, 1.0);
    final curved = curve.transform(t);
    final v = _direction == 1 ? curved : 1.0 - curved;

    if (t >= 1.0) {
      if (_isRepeating) {
        _currentCycle++;
        if (_repeatCount > 0 && _currentCycle >= _repeatCount) {
          _updateValue(v, AnimationStatus.completed);
          return value;
        }
        if (_repeatMode == RepeatMode.reverse) {
          _direction *= -1;
        }
        _startTime = DateTime.now();
        _updateValue(v, AnimationStatus.forward);
        return value;
      }

      _updateValue(v, AnimationStatus.completed);
    } else {
      _updateValue(v, _direction == 1 ? AnimationStatus.forward : AnimationStatus.reverse);
    }
    return value;
  }

  /// Dispose of the controller, releasing timer resources.
  void dispose() {
    _disposed = true;
    stop();
  }
}

/// An [Animatable] that drives itself via an [AnimationController].
///
/// Convenience class that bundles a [Tween] with its [AnimationController].
class TweenAnimation<T extends num> {
  final AnimationController controller;
  late final Animation<T> animation;

  TweenAnimation({
    required T begin,
    required T end,
    Duration duration = const Duration(milliseconds: 200),
    Curve curve = linear,
  }) : controller = AnimationController(duration: duration, curve: curve) {
    animation = Tween<T>(begin: begin, end: end).animate(controller);
  }

  /// The current animated value.
  T get value => animation.value;

  void addListener(void Function() listener) => animation.addListener(listener);
  void removeListener(void Function() listener) => animation.removeListener(listener);

  void addStatusListener(AnimationStatusListener listener) =>
      animation.addStatusListener(listener);
  void removeStatusListener(AnimationStatusListener listener) =>
      animation.removeStatusListener(listener);

  void forward({double? from}) => controller.forward(from: from);
  void reverse({double? from}) => controller.reverse(from: from);
  void dispose() => controller.dispose();
}
