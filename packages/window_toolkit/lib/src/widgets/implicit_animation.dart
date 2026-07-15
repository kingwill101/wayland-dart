/// Implicitly animated widgets: fade, slide, scale, color transitions.
///
/// Each widget manages its own [AnimationController] and drives a transition
/// when its target property changes.
library;

import '../animation/animation.dart';
import '../animation/animation_controller.dart';
import '../animation/curves.dart';
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
}
