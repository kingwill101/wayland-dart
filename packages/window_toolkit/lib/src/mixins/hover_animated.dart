import '../animation/animation_controller.dart';
import '../animation/animatable.dart';
import '../animation/curves.dart';
import '../drawing/color.dart';
import '../widget.dart';

/// Shared 140ms hover transition for interactive controls.
mixin HoverAnimated on Widget {
  AnimationController? _hoverTransition;

  double get hoverProgress =>
      _hoverTransition?.value ?? (isHovered ? 1.0 : 0.0);

  Color transitionHover(Color base, Color hovered) =>
      ColorTween(begin: base, end: hovered).evaluate(hoverProgress);

  @override
  void onHoverChanged(bool hovering) {
    _hoverTransition ??= AnimationController(
      duration: const Duration(milliseconds: 140),
      curve: easeOut,
    )..addListener(requestRepaint);
    if (hovering) {
      _hoverTransition!.forward();
    } else {
      _hoverTransition!.reverse();
    }
  }

  @override
  void dispose() {
    _hoverTransition?.dispose();
    _hoverTransition = null;
    super.dispose();
  }
}
