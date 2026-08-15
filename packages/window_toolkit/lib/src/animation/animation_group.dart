/// Animation combinators: sequential and parallel groups.
///
/// Compose multiple [Animation] objects into a single [Animation<double>].
library;

import 'animation.dart';

// ---------------------------------------------------------------------------
// SequentialAnimation
// ---------------------------------------------------------------------------

/// Runs child animations one after another.
///
/// The [value] is the current child's value. The animation reports
/// [AnimationStatus.forward] while any child is playing and
/// [AnimationStatus.completed] when all children have finished.
///
/// ```dart
/// final seq = SequentialAnimation([
///   AnimationController(duration: Duration(milliseconds: 300)),
///   AnimationController(duration: Duration(milliseconds: 200)),
/// ]);
/// seq.addListener(() => widget.requestRedraw());
/// seq.forward();
/// ```
class SequentialAnimation extends Animation<double> {
  final List<Animation<double>> _animations;
  int _currentIndex = 0;
  bool _playing = false;

  SequentialAnimation(List<Animation<double>> animations)
    : _animations = List.of(animations);

  @override
  double get value {
    if (_animations.isEmpty) return 0.0;
    return _animations[_currentIndex].value;
  }

  @override
  AnimationStatus get status {
    if (!_playing) return AnimationStatus.dismissed;
    if (_currentIndex >= _animations.length) return AnimationStatus.completed;
    if (_currentIndex == _animations.length - 1) {
      return _animations[_currentIndex].status;
    }
    return AnimationStatus.forward;
  }

  void forward() {
    if (_animations.isEmpty) return;
    _playing = true;
    _currentIndex = 0;
    _startCurrent();
  }

  void _startCurrent() {
    if (_currentIndex >= _animations.length) {
      notifyStatusListeners(AnimationStatus.completed);
      return;
    }
    final anim = _animations[_currentIndex];
    anim.addStatusListener(_onChildStatus);
    anim.addListener(_onChildTick);
    try {
      (anim as dynamic).forward();
    } catch (_) {}
  }

  void _onChildStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _currentIndex++;
      if (_currentIndex >= _animations.length) {
        notifyStatusListeners(AnimationStatus.completed);
      } else {
        _startCurrent();
      }
    }
  }

  void _onChildTick() {
    notifyListeners();
  }

  void stop() {
    _playing = false;
  }

  void reset() {
    stop();
    _currentIndex = 0;
    for (final anim in _animations) {
      try {
        (anim as dynamic).reset();
      } catch (_) {}
    }
  }

  void dispose() {
    for (final anim in _animations) {
      try {
        (anim as dynamic).dispose();
      } catch (_) {}
    }
  }
}

// ---------------------------------------------------------------------------
// ParallelAnimationGroup
// ---------------------------------------------------------------------------

/// Runs child animations simultaneously.
///
/// The [value] is the last child's value. The group reports
/// [AnimationStatus.completed] when all children have completed.
///
/// ```dart
/// final group = ParallelAnimationGroup([
///   controllerA.drive(ColorTween(...)),
///   controllerB.drive(OffsetTween(...)),
/// ]);
/// group.forward();
/// ```
class ParallelAnimationGroup extends Animation<double> {
  final List<Animation<double>> _animations;
  int _completedCount = 0;
  bool _playing = false;

  ParallelAnimationGroup(List<Animation<double>> animations)
    : _animations = List.of(animations);

  @override
  double get value {
    if (_animations.isEmpty) return 0.0;
    return _animations.last.value;
  }

  @override
  AnimationStatus get status {
    if (!_playing) return AnimationStatus.dismissed;
    if (_completedCount >= _animations.length) return AnimationStatus.completed;
    return AnimationStatus.forward;
  }

  void forward() {
    if (_animations.isEmpty) return;
    _playing = true;
    _completedCount = 0;

    for (final anim in _animations) {
      anim.addStatusListener(_onChildStatus);
      anim.addListener(_onChildTick);
      try {
        (anim as dynamic).forward();
      } catch (_) {}
    }
  }

  void _onChildStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _completedCount++;
      if (_completedCount >= _animations.length) {
        notifyStatusListeners(AnimationStatus.completed);
      }
    }
  }

  void _onChildTick() {
    notifyListeners();
  }

  void stop() {
    _playing = false;
    for (final anim in _animations) {
      try {
        (anim as dynamic).stop();
      } catch (_) {}
    }
  }

  void dispose() {
    for (final anim in _animations) {
      try {
        (anim as dynamic).dispose();
      } catch (_) {}
    }
  }
}
