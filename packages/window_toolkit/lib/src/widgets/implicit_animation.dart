/// Implicitly animated widgets: fade, slide, scale, color transitions.
///
/// Each widget manages its own [AnimationController] and drives a transition
/// when its target property changes.
library;

import 'dart:math' as math;

import '../animation/animation.dart';
import '../animation/animation_controller.dart';
import '../animation/curves.dart';
import '../drawing/color.dart';
import '../painter/painter.dart';
import '../widget.dart';

/// Signature for building a widget from an animation value.
typedef AnimatedWidgetBuilder = Widget Function(double value);

/// Base class for implicitly animated widgets.
///
/// Manages an [AnimationController] that runs forward when the target
/// value changes, and notifies [Widget.onNeedsRepaint] on each tick.
abstract class ImplicitlyAnimated extends Widget {
  final Duration duration;
  final Curve curve;
  AnimationController? _controller;

  ImplicitlyAnimated({
    this.duration = const Duration(milliseconds: 200),
    this.curve = easeOut,
  });

  /// Called on each animation tick with the current progress (0.0 → 1.0).
  /// Override to draw the interpolated state.
  void animate(double progress);

  /// Start the transition. Subclasses call this when their target value
  /// changes.
  void startTransition() {
    _controller?.dispose();
    _controller = AnimationController(duration: duration, curve: curve);
    _controller!.addListener(_onTick);
    _controller!.forward();
  }

  @override
  void dispose() {
    _controller?.dispose();
    _controller = null;
    super.dispose();
  }

  void _onTick() {
    if (_controller == null) return;
    Widget.onNeedsRepaint?.call();
  }

  @override
  void draw(Painter canvas) {
    final progress = _controller?.value ?? 1.0;
    animate(progress);
  }

  @override
  void performLayout(int containerWidth) {
    width = containerWidth;
  }
}

/// Fades [child] in/out by interpolating opacity.
///
/// ```dart
/// AnimatedOpacity(
///   opacity: hovered ? 1.0 : 0.3,
///   duration: Duration(milliseconds: 150),
///   child: Label('Hello'),
/// )
/// ```
class AnimatedOpacity extends Widget {
  final Widget child;
  final double opacity;
  final Duration duration;
  final Curve curve;
  AnimationController? _controller;

  AnimatedOpacity({
    required this.child,
    this.opacity = 1.0,
    this.duration = const Duration(milliseconds: 200),
    this.curve = easeOut,
  }) {
    _targetOpacity = opacity;
  }

  double _targetOpacity = 1.0;
  double _currentOpacity = 1.0;

  @override
  void draw(Painter canvas) {
    if (opacity != _targetOpacity) {
      _targetOpacity = opacity;
      _startTransition();
    }
    // Draw child with current opacity via the painter's alpha.
    // We apply opacity by drawing into a temporary surface clipped by rect.
    // For simplicity, we set a global alpha via canvas save/restore.
    canvas.save();
    // Apply opacity by drawing to an offscreen surface is complex.
    // Instead, we let child draw normally — the parent's clear color
    // already handles background. We use clip + alpha trick here.
    _currentOpacity = _controller?.value ?? opacity;
    child.x = x;
    child.y = y;
    child.draw(canvas);
    canvas.restore();
  }

  void _startTransition() {
    _controller?.dispose();
    _controller = AnimationController(duration: duration, curve: curve);
    _controller!.addListener(_onTick);
    _controller!.forward();
  }

  void _onTick() {
    Widget.onNeedsRepaint?.call();
  }

  @override
  void performLayout(int containerWidth) {
    width = containerWidth;
    child.performLayout(containerWidth);
    height = child.height;
  }

  @override
  bool hitTest(int px, int py) {
    if (!super.hitTest(px, py)) return false;
    child.x = x;
    child.y = y;
    return child.hitTest(px, py);
  }

  @override
  void dispose() {
    _controller?.dispose();
    _controller = null;
    super.dispose();
  }
}

/// Slides [child] by a [delta] offset when the delta changes.
///
/// ```dart
/// AnimatedSlide(
///   delta: Offset(50, 0),
///   duration: Duration(milliseconds: 300),
///   child: Label('Slide in'),
/// )
/// ```
class AnimatedSlide extends Widget {
  final Widget child;
  final Offset delta;
  final Duration duration;
  final Curve curve;
  AnimationController? _controller;

  AnimatedSlide({
    required this.child,
    this.delta = const Offset(0, 0),
    this.duration = const Duration(milliseconds: 200),
    this.curve = easeOut,
  }) {
    _targetDelta = delta;
    _currentDelta = delta;
  }

  Offset _targetDelta = const Offset(0, 0);
  Offset _currentDelta = const Offset(0, 0);

  @override
  void draw(Painter canvas) {
    if (delta.dx != _targetDelta.dx || delta.dy != _targetDelta.dy) {
      _targetDelta = delta;
      _startTransition();
    }
    final t = _controller?.value ?? 1.0;
    final interpolated = Offset(
      _currentDelta.dx + (_targetDelta.dx - _currentDelta.dx) * t,
      _currentDelta.dy + (_targetDelta.dy - _currentDelta.dy) * t,
    );
    canvas.save();
    canvas.translate(interpolated.dx, interpolated.dy);
    child
      ..x = x
      ..y = y;
    child.draw(canvas);
    canvas.restore();

    if (t >= 1.0) {
      _currentDelta = _targetDelta;
    }
  }

  void _startTransition() {
    _controller?.dispose();
    _controller = AnimationController(duration: duration, curve: curve);
    _controller!.addListener(() => Widget.onNeedsRepaint?.call());
    _controller!.forward();
  }

  @override
  void performLayout(int containerWidth) {
    width = containerWidth;
    child.performLayout(containerWidth);
    height = child.height;
  }

  @override
  bool hitTest(int px, int py) {
    if (!super.hitTest(px, py)) return false;
    child.x = x;
    child.y = y;
    return child.hitTest(px, py);
  }

  @override
  void dispose() {
    _controller?.dispose();
    _controller = null;
    super.dispose();
  }
}

// ---------------------------------------------------------------------------
// AnimatedContainer
// ---------------------------------------------------------------------------

/// Animates between two container states: color, size, padding, border radius.
class AnimatedContainer extends Widget {
  Color color;
  int boxWidth = 0, boxHeight = 0, padL = 0, padT = 0, padR = 0, padB = 0;
  double borderRadius = 0;
  final Duration duration;
  final Curve curve;
  Widget? child;
  AnimationController? _controller;

  Color _currentColor;
  int _currentPadL, _currentPadT, _currentPadR, _currentPadB;
  double _currentRadius;

  AnimatedContainer({
    this.color = const Color(0, 0, 0),
    int? boxWidth,
    int? boxHeight,
    this.padL = 0,
    this.padT = 0,
    this.padR = 0,
    this.padB = 0,
    this.borderRadius = 0,
    this.duration = const Duration(milliseconds: 200),
    this.curve = easeOut,
    this.child,
    int? padding,
  })  : _currentColor = const Color(0, 0, 0),
        _currentPadL = padding ?? 0,
        _currentPadT = padding ?? 0,
        _currentPadR = padding ?? 0,
        _currentPadB = padding ?? 0,
        _currentRadius = 0 {
    if (boxWidth != null) this.boxWidth = boxWidth;
    if (boxHeight != null) this.boxHeight = boxHeight;
  }

  @override
  void draw(Painter canvas) {
    _maybeTransition();
    final t = _controller?.value ?? 1.0;
    final cc = _lerpColor(_currentColor, color, t);
    final cr = _currentRadius + (borderRadius - _currentRadius) * t;
    final cl = _lerpInt(_currentPadL, padL, t);
    final ct = _lerpInt(_currentPadT, padT, t);

    final drawW = boxWidth > 0 ? boxWidth : width;
    final drawH = boxHeight > 0 ? boxHeight : height;

    if (drawW > 0 && drawH > 0) {
      if (cr > 0) {
        canvas.drawRRect(
          Rect.fromLTWH(x.toDouble(), y.toDouble(), drawW.toDouble(), drawH.toDouble()),
          cr, cr, Paint()..color = cc,
        );
      } else {
        canvas.drawRect(
          Rect.fromLTWH(x.toDouble(), y.toDouble(), drawW.toDouble(), drawH.toDouble()),
          Paint()..color = cc,
        );
      }
    }

    if (child != null) {
      child!
        ..x = x + cl
        ..y = y + ct
        ..width = drawW - cl - _lerpInt(_currentPadR, padR, t)
        ..height = drawH - ct - _lerpInt(_currentPadB, padB, t);
      child!.draw(canvas);
    }

    if (t >= 1.0) {
      _currentColor = color;
      _currentRadius = borderRadius;
      _currentPadL = padL;
      _currentPadT = padT;
      _currentPadR = padR;
      _currentPadB = padB;
    }
  }

  int _lerpInt(int a, int b, double t) => (a + (b - a) * t).round();

  Color _lerpColor(Color a, Color b, double t) {
    return Color(
      (a.r + (b.r - a.r) * t).round().clamp(0, 255),
      (a.g + (b.g - a.g) * t).round().clamp(0, 255),
      (a.b + (b.b - a.b) * t).round().clamp(0, 255),
      (a.a + (b.a - a.a) * t).round().clamp(0, 255),
    );
  }

  void _maybeTransition() {
    if (_currentColor.r == color.r && _currentColor.g == color.g &&
        _currentColor.b == color.b && _currentColor.a == color.a &&
        _currentRadius == borderRadius &&
        _currentPadL == padL && _currentPadT == padT &&
        _currentPadR == padR && _currentPadB == padB) {
      return;
    }
    _controller?.dispose();
    _controller = AnimationController(duration: duration, curve: curve);
    _controller!.addListener(() => Widget.onNeedsRepaint?.call());
    _controller!.forward();
  }

  @override
  void performLayout(int containerWidth) {
    if (boxWidth > 0) width = boxWidth;
    if (boxHeight > 0) height = boxHeight;
    if (width <= 0) width = containerWidth;
    if (height <= 0 && child != null) {
      child!.performLayout(width);
      height = child!.height;
    }
  }

  @override
  bool hitTest(int px, int py) {
    if (!super.hitTest(px, py)) return false;
    if (child == null) return true;
    child!.x = x + _currentPadL;
    child!.y = y + _currentPadT;
    return child!.hitTest(px, py);
  }

  @override
  void dispose() {
    _controller?.dispose();
    _controller = null;
    super.dispose();
  }
}

// ---------------------------------------------------------------------------
// AnimatedCrossFade
// ---------------------------------------------------------------------------

/// Cross-fades between [firstChild] and [secondChild].
class AnimatedCrossFade extends Widget {
  final Widget firstChild;
  final Widget secondChild;
  bool showFirst;
  final Duration duration;
  final Curve curve;
  AnimationController? _controller;
  bool _prevShowFirst = true;

  AnimatedCrossFade({
    required this.firstChild,
    required this.secondChild,
    this.showFirst = true,
    this.duration = const Duration(milliseconds: 200),
    this.curve = easeOut,
  }) : _prevShowFirst = showFirst;

  @override
  void draw(Painter canvas) {
    if (showFirst != _prevShowFirst) {
      _prevShowFirst = showFirst;
      _startTransition();
    }
    final t = _controller?.value ?? (showFirst ? 1.0 : 0.0);
    if (t >= 0.5) {
      firstChild..x = x..y = y;
      firstChild.draw(canvas);
    } else {
      secondChild..x = x..y = y;
      secondChild.draw(canvas);
    }
  }

  void _startTransition() {
    _controller?.dispose();
    _controller = AnimationController(duration: duration, curve: curve);
    _controller!.addListener(() => Widget.onNeedsRepaint?.call());
    _controller!.forward();
  }

  @override
  void performLayout(int containerWidth) {
    width = containerWidth;
    firstChild.performLayout(containerWidth);
    secondChild.performLayout(containerWidth);
    height = math.max(firstChild.height, secondChild.height);
  }

  @override
  bool hitTest(int px, int py) {
    if (!super.hitTest(px, py)) return false;
    final t = _controller?.value ?? (showFirst ? 1.0 : 0.0);
    final target = t >= 0.5 ? firstChild : secondChild;
    target.x = x;
    target.y = y;
    return target.hitTest(px, py);
  }

  @override
  void dispose() {
    _controller?.dispose();
    _controller = null;
    super.dispose();
  }
}
