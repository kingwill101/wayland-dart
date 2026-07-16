/// AnimatedBuilder using StatefulWidget + Element tree lifecycle.
///
/// The animation listener is added in [State.initState] and removed in
/// [State.dispose], ensuring proper cleanup even if the widget is removed
/// from the tree before the animation completes.
///
/// ```dart
/// final controller = AnimationController(duration: Duration(milliseconds: 300));
/// final builder = StatefulAnimatedBuilder(
///   animation: controller,
///   builder: (v) => Label('${v.round()}'),
/// );
/// controller.forward();
/// ```
import 'package:layout_engine/layout_engine.dart' show BuildContext, State, StatefulWidget;

import '../animation/animation.dart';
import '../painter/painter.dart';
import '../widget.dart';

/// Animated builder with proper Element tree lifecycle.
class StatefulAnimatedBuilder extends StatefulWidget {
  final Animation<dynamic> animation;
  final Widget Function(double value) builder;

  StatefulAnimatedBuilder({
    required this.animation,
    required this.builder,
  });

  @override
  State createState() => _AnimatedBuilderState();
}

class _AnimatedBuilderState extends State<StatefulAnimatedBuilder> {
  @override
  void initState() {
    super.initState();
    widget.animation.addListener(_onTick);
  }

  void _onTick() {
    Widget.onNeedsRepaint?.call();
  }

  @override
  void dispose() {
    widget.animation.removeListener(_onTick);
    super.dispose();
  }

  @override
  ElementWidget build(BuildContext context) {
    final v = (widget.animation.value as num).toDouble();
    return _AnimatedBuilderRender(
      animation: widget.animation,
      builder: widget.builder,
      value: v,
    );
  }
}

/// Rendering widget — does the actual draw/performLayout/hitTest.
class _AnimatedBuilderRender extends Widget {
  final Animation<dynamic> animation;
  final Widget Function(double value) builder;
  final double value;

  _AnimatedBuilderRender({
    required this.animation,
    required this.builder,
    required this.value,
  });

  @override
  void draw(Painter canvas) {
    final built = builder(value);
    built..x = x..y = y..width = width..height = height;
    built.draw(canvas);
  }

  @override
  void performLayout(int containerWidth) {
    width = containerWidth;
  }

  @override
  bool hitTest(int px, int py) {
    if (!super.hitTest(px, py)) return false;
    final built = builder(value);
    built..x = x..y = y..width = width..height = height;
    return built.hitTest(px, py);
  }
}
