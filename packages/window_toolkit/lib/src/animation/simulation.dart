/// Physics simulation primitives: spring, friction, and driving controller.
///
/// Simulations produce a position `x(t)` and velocity `dx(t)` for a given
/// time `t`. Use [SimulationController] to drive an [Animation<double>] from
/// a [Simulation].
library;

import 'dart:math' as math;
import '../event_loop.dart' as el;
import 'animation.dart';

// ---------------------------------------------------------------------------
// Simulation — base class
// ---------------------------------------------------------------------------

/// A physics simulation that evolves over time.
abstract class Simulation {
  /// The position at time [t].
  double x(double t);

  /// The velocity at time [t].
  double dx(double t);

  /// Whether the simulation has settled (is effectively done).
  bool isDone(double t);
}

// ---------------------------------------------------------------------------
// FrictionSimulation
// ---------------------------------------------------------------------------

/// A simulation that decelerates with friction.
///
/// Models an object sliding with friction, gradually slowing to a stop.
class FrictionSimulation extends Simulation {
  final double _initialPosition;
  final double _initialVelocity;
  final double _friction;

  FrictionSimulation({
    required double initialPosition,
    required double initialVelocity,
    double friction = 0.05,
  })  : _initialPosition = initialPosition,
        _initialVelocity = initialVelocity,
        _friction = friction;

  @override
  double x(double t) {
    if (t < 0) return _initialPosition;
    if (isDone(t)) return _finalPosition;
    return _initialPosition + _initialVelocity * (1 - math.exp(-_friction * t)) / _friction;
  }

  @override
  double dx(double t) {
    if (t < 0) return _initialVelocity;
    if (isDone(t)) return 0.0;
    return _initialVelocity * math.exp(-_friction * t);
  }

  @override
  bool isDone(double t) => dx(t).abs() < 0.1;

  double get _finalPosition => _initialPosition + _initialVelocity / _friction;
}

// ---------------------------------------------------------------------------
// SimulationController — drives an Animation<double> from a Simulation
// ---------------------------------------------------------------------------

/// An [Animation<double>] driven by a [Simulation].
///
/// ```dart
/// final sim = SpringSimulation(
///   initialPosition: 0, initialVelocity: 200, finalPosition: 100,
/// );
/// final ctrl = SimulationController(simulation: sim);
/// ctrl.addListener(() => widget.requestRedraw());
/// ctrl.start();
/// ```
class SimulationController extends Animation<double> {
  final Simulation simulation;
  DateTime? _startTime;
  el.Timer? _timer;
  bool _disposed = false;

  SimulationController({required this.simulation});

  double _value = 0.0;
  AnimationStatus _status = AnimationStatus.dismissed;

  @override
  double get value => _value;

  @override
  AnimationStatus get status => _status;

  bool get isAnimating => _timer != null && _timer!.isActive;

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

  /// Start the simulation.
  void start() {
    if (_disposed) return;
    _startTime = DateTime.now();
    _scheduleNextFrame();
  }

  void _scheduleNextFrame() {
    if (_disposed) return;
    _timer?.cancel();
    _timer = el.EventLoop.instance.addTimer(
      const Duration(milliseconds: 16),
      _tick,
    );
  }

  void _tick() {
    if (_disposed) return;
    final elapsed = DateTime.now().difference(_startTime ?? DateTime.now());
    final t = elapsed.inMicroseconds / 1000000.0;

    if (simulation.isDone(t)) {
      _timer?.cancel();
      _timer = null;
      _updateValue(simulation.x(t), AnimationStatus.completed);
      return;
    }

    _updateValue(simulation.x(t), AnimationStatus.forward);
    _scheduleNextFrame();
  }

  /// Advance the simulation by [elapsed] time (for testing).
  double tick(Duration elapsed) {
    if (_disposed) return value;
    final t = elapsed.inMicroseconds / 1000000.0;

    if (simulation.isDone(t)) {
      _updateValue(simulation.x(t), AnimationStatus.completed);
    } else {
      _updateValue(simulation.x(t), AnimationStatus.forward);
    }
    return value;
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  void dispose() {
    _disposed = true;
    stop();
  }
}

/// A damped spring simulation.
class SpringSimulation extends Simulation {
  final double _finalPosition;
  final double _initialPosition;
  final double _initialVelocity;

  // Computed coefficients
  final double _w0; // undamped angular frequency
  final double _zeta; // damping ratio
  late final double _wd; // damped angular frequency

  SpringSimulation({
    required double initialPosition,
    required double initialVelocity,
    required double finalPosition,
    double springConstant = 100.0,
    double damping = 10.0,
    double mass = 1.0,
  })  : _initialPosition = initialPosition,
        _initialVelocity = initialVelocity,
        _finalPosition = finalPosition,
        _w0 = math.sqrt(springConstant / mass),
        _zeta = damping / (2 * math.sqrt(springConstant * mass)) {
    _wd = _zeta < 1.0
        ? math.sqrt(springConstant / mass - damping * damping / (4 * mass * mass))
        : 0.0;
  }

  @override
  double x(double t) {
    if (t < 0) return _initialPosition;
    if (isDone(t)) return _finalPosition;

    final x0 = _initialPosition - _finalPosition;

    if (_zeta < 1.0) {
      // Underdamped: oscillates with exponential decay
      final A = x0;
      final B = (_initialVelocity + _zeta * _w0 * x0) / _wd;
      final envelope = math.exp(-_zeta * _w0 * t);
      return _finalPosition + envelope * (A * math.cos(_wd * t) + B * math.sin(_wd * t));
    } else if (_zeta == 1.0) {
      // Critically damped
      final A = x0;
      final B = _initialVelocity + _w0 * x0;
      return _finalPosition + math.exp(-_w0 * t) * (A + B * t);
    } else {
      // Overdamped
      final r1 = -_zeta * _w0 + _w0 * math.sqrt(_zeta * _zeta - 1);
      final r2 = -_zeta * _w0 - _w0 * math.sqrt(_zeta * _zeta - 1);
      final c2 = (_initialVelocity - r1 * x0) / (r2 - r1);
      final c1 = x0 - c2;
      return _finalPosition + c1 * math.exp(r1 * t) + c2 * math.exp(r2 * t);
    }
  }

  @override
  double dx(double t) {
    if (t < 0) return _initialVelocity;
    if (isDone(t)) return 0.0;
    const epsilon = 1e-6;
    return (x(t + epsilon) - x(math.max(0.0, t - epsilon))) / (2 * epsilon);
  }

  @override
  bool isDone(double t) {
    if (t < 0) return false;
    final curr = x(t);
    final vel = dx(t);
    return (curr - _finalPosition).abs() < 0.1 && vel.abs() < 0.1;
  }
}