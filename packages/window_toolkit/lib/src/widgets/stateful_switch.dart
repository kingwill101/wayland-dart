/// Stateful Switch with Element tree lifecycle.
///
/// Unlike the plain [Switch], this version uses [StatefulWidget] with
/// proper `initState()`, `dispose()`, and `setState()` lifecycle.
///
/// Use with [ElementHost]:
/// ```dart
/// ElementHost(child: StatefulSwitch(value: true))
/// ```
library;

import '../drawing/color.dart';
import '../mixins/hoverable.dart';
import '../mixins/hover_animated.dart';
import '../painter/painter.dart';
import '../style.dart';
import '../style/style_patch.dart';
import '../widget.dart';

class StatefulSwitch extends StatefulWidget {
  final bool value;
  final void Function(bool)? onChanged;

  StatefulSwitch({this.value = false, this.onChanged});

  @override
  State createState() => _SwitchState();
}

class _SwitchState extends State<StatefulSwitch> {
  late bool _value;

  @override
  void initState() {
    super.initState();
    _value = widget.value;
  }

  @override
  void didUpdateWidget(covariant StatefulSwitch oldWidget) {
    super.didUpdateWidget(oldWidget);
    _value = widget.value;
  }

  void toggle() {
    setState(() => _value = !_value);
    widget.onChanged?.call(_value);
  }

  @override
  ElementWidget build(BuildContext context) {
    return _SwitchRender(value: _value, onToggle: toggle);
  }
}

class _SwitchRender extends Widget with Hoverable, HoverAnimated {
  final bool value;
  final VoidCallback onToggle;

  _SwitchRender({required this.value, required this.onToggle}) {
    onClick = () {
      onToggle();
      return true;
    };
    width = 42;
    height = 22;
  }

  @override
  bool get acceptsFocus => true;

  @override
  Style styleRole() => Style(
    color: palette.light,
    backgroundColor: value ? const Color(0, 180, 80) : palette.mid,
    borderColor: palette.shadow,
    borderRadius: height > 0 ? height / 2 : 11,
  );

  @override
  void draw(Painter canvas) {
    final base = resolvedStyle();
    final trackColor = base.backgroundColor!;
    final fill = transitionHover(
      trackColor,
      Color.blend(trackColor, const Color(255, 255, 255, 24)),
    );

    drawStyledBox(
      canvas,
      style: base.overlay(StylePatch(backgroundColor: fill)),
    );

    final knobRadius = (height / 2) - 2;
    final knobCenterX = value ? x + width - height ~/ 2 : x + height ~/ 2;
    final knobCenterY = y + height ~/ 2;
    canvas.drawCircle(
      Offset(knobCenterX.toDouble(), knobCenterY.toDouble()),
      knobRadius.toDouble(),
      Paint()..color = styledColor(base.color, base),
    );
  }

  @override
  void performLayout(int containerWidth) {
    width = containerWidth > 0 ? containerWidth : 42;
    height = 22;
  }
}
