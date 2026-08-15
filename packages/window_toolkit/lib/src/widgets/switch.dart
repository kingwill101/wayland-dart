import '../drawing/color.dart';
import '../interaction.dart';
import '../mixins/hoverable.dart';
import '../mixins/hover_animated.dart';
import '../painter/painter.dart';
import '../style.dart';
import '../style/style_patch.dart';

import '../widget.dart';

class Switch extends Widget with Hoverable, HoverAnimated {
  bool value;
  final Color? _trackOnColor;
  final Color? _trackOffColor;
  final Color? _thumbColor;
  final Color? _borderColor;
  int trackWidth;
  int trackHeight;
  VoidCallback? onChanged;

  Switch({
    this.value = false,
    Color? trackOnColor,
    Color? trackOffColor,
    Color? thumbColor,
    Color? borderColor,
    this.trackWidth = 42,
    this.trackHeight = 22,
    this.onChanged,
    WidgetKey? key,
  }) : assert(trackWidth > 0, 'Switch trackWidth must be > 0'),
       assert(trackHeight > 0, 'Switch trackHeight must be > 0'),
       _trackOnColor = trackOnColor,
       _trackOffColor = trackOffColor,
       _thumbColor = thumbColor,
       _borderColor = borderColor {
    setInteractionState(WidgetState.checked, value);
    width = trackWidth;
    height = trackHeight;
    onClick = () {
      toggle();
      return true;
    };
    tabIndex = 1;
  }

  Color get trackOnColor => _trackOnColor ?? palette.success;
  Color get trackOffColor => _trackOffColor ?? palette.mid;
  Color get thumbColor => _thumbColor ?? palette.light;
  Color get borderColor => _borderColor ?? palette.shadow;

  @override
  bool get acceptsFocus => true;

  @override
  Style styleRole() => Style(
    color: thumbColor,
    backgroundColor: value ? trackOnColor : trackOffColor,
    borderColor: borderColor,
  );

  void toggle() {
    setState(() {
      value = !value;
      setInteractionState(WidgetState.checked, value);
    });
    onChanged?.call();
  }

  @override
  void draw(Painter canvas) {
    final base = resolvedStyle();
    final hover = resolvedStyleOn(
      const ['hover'],
      local: StylePatch(
        backgroundColor: Color.blend(
          value ? trackOnColor : trackOffColor,
          const Color(255, 255, 255, 24),
        ),
      ),
    );
    final trackColor = base.backgroundColor!;
    final fill = transitionHover(trackColor, hover.backgroundColor!);

    drawStyledBox(
      canvas,
      style: base.overlay(
        StylePatch(
          backgroundColor: fill,
          borderTopLeftRadius: base.borderRadius == 0
              ? (height / 2).toDouble()
              : null,
          borderTopRightRadius: base.borderRadius == 0
              ? (height / 2).toDouble()
              : null,
          borderBottomLeftRadius: base.borderRadius == 0
              ? (height / 2).toDouble()
              : null,
          borderBottomRightRadius: base.borderRadius == 0
              ? (height / 2).toDouble()
              : null,
        ),
      ),
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
}
