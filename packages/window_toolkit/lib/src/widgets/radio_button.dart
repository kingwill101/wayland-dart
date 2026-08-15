import '../drawing/color.dart';
import '../interaction.dart';
import '../mixins/hoverable.dart';
import '../mixins/hover_animated.dart';
import '../painter/painter.dart';
import '../style.dart';
import '../style/style_patch.dart';

import '../widget.dart';

class RadioButton extends Widget with Hoverable, HoverAnimated {
  String label;
  bool selected;
  Color borderColor;
  Color selectedColor;
  Color backgroundColor;
  Color textColor;
  int diameter;
  VoidCallback? onChanged;

  RadioButton(
    this.label, {
    this.selected = false,
    this.borderColor = const Color(120, 120, 120),
    this.selectedColor = const Color(255, 255, 255),
    this.backgroundColor = const Color(36, 36, 36),
    this.textColor = const Color(255, 255, 255),
    this.diameter = 18,
    this.onChanged,
  }) {
    width = diameter + 8 + label.length * 8;
    height = diameter > 16 ? diameter : 16;
    setInteractionState(WidgetState.selected, selected);
    onClick = () {
      select();
      return true;
    };
    tabIndex = 1;
  }

  @override
  bool get acceptsFocus => true;

  @override
  Style styleRole() => Style(
    color: textColor,
    backgroundColor: backgroundColor,
    borderColor: borderColor,
  );

  void select() {
    if (!selected) {
      setState(() {
        selected = true;
        setInteractionState(WidgetState.selected, true);
      });
      onChanged?.call();
    }
  }

  void setSelected(bool value) {
    if (selected != value) {
      setState(() {
        selected = value;
        setInteractionState(WidgetState.selected, value);
      });
      onChanged?.call();
    }
  }

  @override
  void draw(Painter canvas) {
    final base = resolvedStyle();
    final hover = resolvedStyleOn(
      const ['hover'],
      local: StylePatch(
        backgroundColor: Color.blend(
          backgroundColor,
          const Color(255, 255, 255, 18),
        ),
      ),
    );
    final cy = y + height ~/ 2;
    final cx = x + diameter ~/ 2;

    canvas.drawCircle(
      Offset(cx.toDouble(), cy.toDouble()),
      (diameter / 2).toDouble(),
      Paint()
        ..color = transitionHover(
          base.backgroundColor!,
          hover.backgroundColor!,
        ),
    );

    canvas.drawCircle(
      Offset(cx.toDouble(), cy.toDouble()),
      (diameter / 2).toDouble(),
      Paint()
        ..color = base.borderColor
        ..style = PaintStyle.stroke,
    );

    if (selected) {
      canvas.drawCircle(
        Offset(cx.toDouble(), cy.toDouble()),
        (diameter / 3).toDouble(),
        Paint()..color = base.color,
      );
    }

    canvas.drawText(
      label,
      Offset(
        (x + diameter + 8).toDouble(),
        (y + (height - 16) ~/ 2).toDouble(),
      ),
      color: base.color,
      size: 16,
    );
  }
}
