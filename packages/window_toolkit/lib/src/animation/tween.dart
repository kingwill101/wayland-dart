/// Tweens map [Animation<double>] values to concrete types.
library;

import 'animation.dart';

/// An [Animation] whose value is interpolated between [begin] and [end].
class Tween<T extends num> extends Animation<T> {
  final T Function(double t) _lerp;

  Tween({required T begin, required T end})
      : _lerp = _makeLerp(begin, end),
        _value = begin;

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

  T _value;
  Animation<double>? _parent;

  @override
  T get value => _value;

  @override
  late AnimationStatus status;

  /// Drive this tween from an [Animation<double>] parent.
  void animate(Animation<double> parent) {
    _parent?.removeListener(_onParentChanged);
    _parent = parent;
    parent.addListener(_onParentChanged);
    parent.addStatusListener((s) {
      status = s;
      notifyStatusListeners(s);
    });
  }

  void _onParentChanged() {
    _value = _lerp(_parent!.value);
    notifyListeners();
  }
}
