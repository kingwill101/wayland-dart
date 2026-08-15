/// `Animatable<T>` — the "what" of an animation: a pure function of progress.
///
/// Separates interpolation logic from the driving mechanism ([Animation]).
/// Use [animate] to bind this to an [Animation<double>] (e.g. an
/// [AnimationController]), producing an [Animation<T>] that updates live.
///
/// ```dart
/// final tween = Tween<double>(begin: 0, end: 100) as Animatable<double>;
/// final anim = tween.animate(controller);
/// ```
library;

import '../drawing/color.dart';
import '../painter/painter.dart' show Offset, Size, Rect;
import 'animation.dart' show Animation, AnimationStatus;

// ---------------------------------------------------------------------------
// Animatable<T> — base class
// ---------------------------------------------------------------------------

/// An object that can produce a value of type `T` given a `t` in [0.0, 1.0].
///
/// This is the "interpolation" half of the animation system, separate from
/// the "driving" half ([Animation<double>]). Use [animate] to bridge them.
abstract class Animatable<T> {
  const Animatable();

  /// Return the value of this animation at progress [t].
  ///
  /// [t] should be between 0.0 and 1.0 inclusive.
  T evaluate(double t);

  /// Drive this animatable from [parent], producing a live [Animation<T>].
  ///
  /// The returned animation updates its value whenever [parent] changes,
  /// forwarding [AnimationStatus] changes from [parent].
  Animation<T> animate(Animation<double> parent) {
    return _AnimatedAnimation<T>(this, parent);
  }

  /// Chain this animatable with [next], creating a sequence.
  ///
  /// The combined animatable uses this for `t` in [0.0, 0.5) and [next]
  /// for `t` in [0.5, 1.0].
  Animatable<T> chain(Animatable<T> next) {
    return _ChainedAnimatable<T>(this, next);
  }
}

// ---------------------------------------------------------------------------
// _AnimatedAnimation — bridges Animatable<T> to Animation<T>
// ---------------------------------------------------------------------------

class _AnimatedAnimation<T> extends Animation<T> {
  final Animatable<T> _animatable;
  final Animation<double> _parent;

  _AnimatedAnimation(this._animatable, this._parent)
    : _value = _animatable.evaluate(_parent.value) {
    _parent.addListener(_onParentChanged);
    _parent.addStatusListener(_onParentStatusChanged);
  }

  T _value;

  @override
  T get value => _value;

  @override
  AnimationStatus get status => _parent.status;

  void _onParentChanged() {
    _value = _animatable.evaluate(_parent.value);
    notifyListeners();
  }

  void _onParentStatusChanged(AnimationStatus status) {
    notifyStatusListeners(status);
  }
}

// ---------------------------------------------------------------------------
// _ChainedAnimatable — composes two animatables in sequence
// ---------------------------------------------------------------------------

class _ChainedAnimatable<T> extends Animatable<T> {
  final Animatable<T> _first;
  final Animatable<T> _second;

  _ChainedAnimatable(this._first, this._second);

  @override
  T evaluate(double t) {
    if (t < 0.5) {
      return _first.evaluate(t * 2.0);
    } else {
      return _second.evaluate((t - 0.5) * 2.0);
    }
  }
}

// ---------------------------------------------------------------------------
// Tween<T extends num> — numeric interpolation
// ---------------------------------------------------------------------------

/// An [Animatable] that interpolates between [begin] and [end].
///
/// Supports `int` (rounded) and `double` types.
class Tween<T extends num> extends Animatable<T> {
  final T Function(double t) _lerp;

  Tween({required T begin, required T end}) : _lerp = _makeLerp(begin, end);

  static T Function(double t) _makeLerp<T extends num>(T begin, T end) {
    if (begin is int && end is int) {
      final b = begin as int;
      final e = end as int;
      return (t) => (b + (e - b) * t).round() as T;
    }
    final b = begin.toDouble();
    final e = end.toDouble();
    return (t) => (b + (e - b) * t) as T;
  }

  @override
  T evaluate(double t) => _lerp(t);
}

// ---------------------------------------------------------------------------
// ColorTween
// ---------------------------------------------------------------------------

/// An [Animatable] that interpolates between two [Color] values.
class ColorTween extends Animatable<Color> {
  final Color begin;
  final Color end;

  const ColorTween({required this.begin, required this.end});

  @override
  Color evaluate(double t) {
    return Color(
      (begin.r + (end.r - begin.r) * t).round().clamp(0, 255),
      (begin.g + (end.g - begin.g) * t).round().clamp(0, 255),
      (begin.b + (end.b - begin.b) * t).round().clamp(0, 255),
      (begin.a + (end.a - begin.a) * t).round().clamp(0, 255),
    );
  }
}

// ---------------------------------------------------------------------------
// OffsetTween
// ---------------------------------------------------------------------------

/// An [Animatable] that interpolates between two [Offset] values.
class OffsetTween extends Animatable<Offset> {
  final Offset begin;
  final Offset end;

  const OffsetTween({required this.begin, required this.end});

  @override
  Offset evaluate(double t) {
    return Offset(
      begin.dx + (end.dx - begin.dx) * t,
      begin.dy + (end.dy - begin.dy) * t,
    );
  }
}

// ---------------------------------------------------------------------------
// SizeTween
// ---------------------------------------------------------------------------

/// An [Animatable] that interpolates between two [Size] values.
class SizeTween extends Animatable<Size> {
  final Size begin;
  final Size end;

  const SizeTween({required this.begin, required this.end});

  @override
  Size evaluate(double t) {
    return Size(
      begin.width + (end.width - begin.width) * t,
      begin.height + (end.height - begin.height) * t,
    );
  }
}

// ---------------------------------------------------------------------------
// RectTween
// ---------------------------------------------------------------------------

/// An [Animatable] that interpolates between two [Rect] values.
class RectTween extends Animatable<Rect> {
  final Rect begin;
  final Rect end;

  const RectTween({required this.begin, required this.end});

  @override
  Rect evaluate(double t) {
    return Rect.fromLTRB(
      begin.left + (end.left - begin.left) * t,
      begin.top + (end.top - begin.top) * t,
      begin.right + (end.right - begin.right) * t,
      begin.bottom + (end.bottom - begin.bottom) * t,
    );
  }
}
