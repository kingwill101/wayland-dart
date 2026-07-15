/// Animation framework for window_toolkit.
///
/// Ported from artisanal_widgets, adapted to use [EventLoop.Timer]
/// instead of TEA [Cmd.tick] for frame scheduling.
library;

/// The status of an animation.
enum AnimationStatus {
  dismissed,
  forward,
  reverse,
  completed,
}

/// Signature for listeners receiving [AnimationStatus] changes.
typedef AnimationStatusListener = void Function(AnimationStatus status);

/// An animation with a value of type [T].
///
/// Subclasses implement [value] and notify listeners when it changes.
abstract class Animation<T> {
  T get value;
  AnimationStatus get status;

  final List<void Function()> _listeners = [];
  final List<AnimationStatusListener> _statusListeners = [];

  void addListener(void Function() listener) => _listeners.add(listener);
  void removeListener(void Function() listener) => _listeners.remove(listener);

  void addStatusListener(AnimationStatusListener listener) =>
      _statusListeners.add(listener);
  void removeStatusListener(AnimationStatusListener listener) =>
      _statusListeners.remove(listener);

  /// Notify value listeners that the animation changed.
  /// Subclasses call this when [value] changes.
  void notifyListeners() {
    for (final l in List.of(_listeners)) {
      l();
    }
  }

  /// Notify status listeners that [status] changed.
  /// Subclasses call this when [status] changes.
  void notifyStatusListeners(AnimationStatus status) {
    for (final l in List.of(_statusListeners)) {
      l(status);
    }
  }

  @override
  String toString() => '$runtimeType($value, $status)';
}
