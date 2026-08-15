import '../drawing/color.dart';
import '../interaction.dart';
import '../mixins/hoverable.dart';
import '../mixins/hover_animated.dart';
import '../painter/painter.dart';
import '../style.dart';
import '../style/style_patch.dart';

import '../widget.dart';

class Checkbox extends Widget with Hoverable, HoverAnimated {
  bool checked;
  final Color? _boxColor;
  final Color? _borderColor;
  final Color? _checkColor;
  int boxSize;
  VoidCallback? onChanged;

  Checkbox({
    this.checked = false,
    Color? boxColor,
    Color? borderColor,
    Color? checkColor,
    this.boxSize = 18,
    this.onChanged,
    WidgetKey? key,
  }) : assert(boxSize > 0, 'Checkbox boxSize must be > 0'),
       _boxColor = boxColor,
       _borderColor = borderColor,
       _checkColor = checkColor {
    setInteractionState(WidgetState.checked, checked);
    width = boxSize;
    height = boxSize;
    tabIndex = 1;
    onClick = () {
      toggle();
      return true;
    };
  }

  Color get boxColor => _boxColor ?? palette.base;
  Color get borderColor => _borderColor ?? palette.mid;
  Color get checkColor => _checkColor ?? palette.text;

  @override
  bool get acceptsFocus => true;

  @override
  void performLayout(int containerWidth) {
    // Checkbox is an intrinsic-size control. Do not let a parent row/card
    // stretch its hit area and drawing bounds to the available width.
    width = boxSize;
    height = boxSize;
  }

  @override
  Style styleRole() => Style(
    color: checkColor,
    backgroundColor: boxColor,
    borderColor: borderColor,
    borderWidth: 1,
  );

  void toggle() {
    setState(() {
      checked = !checked;
      setInteractionState(WidgetState.checked, checked);
    });
    onChanged?.call();
  }

  @override
  void draw(Painter canvas) {
    final base = resolvedStyle();
    final hover = resolvedStyleOn(
      const ['hover'],
      local: StylePatch(
        backgroundColor: Color.blend(boxColor, const Color(255, 255, 255, 18)),
      ),
    );
    final fill = transitionHover(base.backgroundColor!, hover.backgroundColor!);
    drawStyledBox(
      canvas,
      style: base.overlay(StylePatch(backgroundColor: fill)),
    );

    if (checked) {
      final checkPaint = Paint()
        ..color = styledColor(base.color, base)
        ..strokeWidth = 2;
      canvas.drawLine(
        Offset((x + width * 0.22).toDouble(), (y + height * 0.55).toDouble()),
        Offset((x + width * 0.42).toDouble(), (y + height * 0.75).toDouble()),
        checkPaint,
      );
      canvas.drawLine(
        Offset((x + width * 0.40).toDouble(), (y + height * 0.74).toDouble()),
        Offset((x + width * 0.78).toDouble(), (y + height * 0.28).toDouble()),
        checkPaint,
      );
    }
  }
}
