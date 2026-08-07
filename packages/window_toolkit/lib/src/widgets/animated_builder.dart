/// AnimatedBuilder: rebuild on every animation tick.
library;
import '../animation/animation.dart';
import '../painter/painter.dart';
import '../widget.dart';

/// A widget that rebuilds on every tick of a given [Animation].
///
/// Usage:
/// ```dart
/// final controller = AnimationController(duration: Duration(milliseconds: 300));
/// final builder = AnimatedBuilder(
///   animation: controller,
///   builder: (v) => Label('${v.round()}'),
/// );
/// controller.forward();
/// ```
class AnimatedBuilder extends Widget {
  final Animation<dynamic> animation;
  final Widget Function(double value) builder;
  final Widget? child;

  AnimatedBuilder({
    required this.animation,
    required this.builder,
    this.child,
  }) {
    animation.addListener(_onAnimationTick);
  }

  void _onAnimationTick() {
    Widget.onNeedsRepaint?.call();
  }

  @override
  void dispose() {
    animation.removeListener(_onAnimationTick);
    super.dispose();
  }

  double _currentValue() => (animation.value as num).toDouble();

  @override
  void draw(Painter canvas) {
    final v = _currentValue();
    final built = builder(v);
    built
      ..x = x
      ..y = y
      ..width = width
      ..height = height;
    built.draw(canvas);
  }

  @override
  void performLayout(int containerWidth) {
    width = containerWidth;
  }

  @override
  bool hitTest(int px, int py) {
    if (!super.hitTest(px, py)) return false;
    final v = _currentValue();
    final built = builder(v);
    built
      ..x = x
      ..y = y
      ..width = width
      ..height = height;
    return built.hitTest(px, py);
  }
}
