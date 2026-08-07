/// Easing curves for animations.
library;


/// A mapping of the unit interval to the unit interval.
///
/// A curve must map t=0.0 to 0.0 and t=1.0 to 1.0.
abstract class Curve {
  const Curve();

  /// Returns the value of the curve at point [t].
  /// [t] must be between 0.0 and 1.0, inclusive.
  double transform(double t) {
    assert(
      t >= 0.0 && t <= 1.0,
      'Curve.transform parameter t ($t) must be between 0.0 and 1.0.',
    );
    if (t == 0.0 || t == 1.0) return t;
    return transformInternal(t);
  }

  /// Override to define the curve's behavior.
  /// [t] is guaranteed to be in (0.0, 1.0) exclusive.
  double transformInternal(double t);
}

/// A linear curve (identity).
class LinearCurve extends Curve {
  const LinearCurve();
  @override
  double transformInternal(double t) => t;
}

/// A cubic bezier curve.
class CubicCurve extends Curve {
  final double a, b, c, d;
  const CubicCurve(this.a, this.b, this.c, this.d);

  @override
  double transformInternal(double t) {
    final t2 = t * t;
    final t3 = t2 * t;
    return 3 * a * (1 - t) * (1 - t) * t +
        3 * c * (1 - t) * t2 +
        t3;
  }
}

/// Quadratic ease-in curve.
class EaseInCurve extends Curve {
  const EaseInCurve();
  @override
  double transformInternal(double t) => t * t;
}

/// Quadratic ease-out curve.
class EaseOutCurve extends Curve {
  const EaseOutCurve();
  @override
  double transformInternal(double t) => t * (2 - t);
}

/// Quadratic ease-in-out curve.
class EaseInOutCurve extends Curve {
  const EaseInOutCurve();
  @override
  double transformInternal(double t) {
    if (t < 0.5) return 2 * t * t;
    return -1 + (4 - 2 * t) * t;
  }
}

/// Overshoots then returns (like a spring).
class BounceOutCurve extends Curve {
  const BounceOutCurve();
  @override
  double transformInternal(double t) {
    if (t < 1 / 2.75) return 7.5625 * t * t;
    if (t < 2 / 2.75) return 7.5625 * (t -= 1.5 / 2.75) * t + 0.75;
    if (t < 2.5 / 2.75) return 7.5625 * (t -= 2.25 / 2.75) * t + 0.9375;
    return 7.5625 * (t -= 2.625 / 2.75) * t + 0.984375;
  }
}

/// Predefined curves.
const Curve linear = LinearCurve();
const Curve easeIn = EaseInCurve();
const Curve easeOut = EaseOutCurve();
const Curve easeInOut = EaseInOutCurve();
const Curve bounceOut = BounceOutCurve();
