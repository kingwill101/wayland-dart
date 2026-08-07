import '../drawing/color.dart';
import '../painter/painter.dart';

import '../widget.dart';

class RadioButton extends Widget {
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
    onClick = () { select(); return true; };
  }

  void select() {
    if (!selected) {
      setState(() => selected = true);
      onChanged?.call();
    }
  }

  void setSelected(bool value) {
    if (selected != value) {
      setState(() => selected = value);
      onChanged?.call();
    }
  }

  @override
  void draw(Painter canvas) {
    final cy = y + height ~/ 2;
    final cx = x + diameter ~/ 2;

    canvas.drawCircle(
      Offset(cx.toDouble(), cy.toDouble()),
      (diameter / 2).toDouble(),
      Paint()..color = backgroundColor,
    );

    canvas.drawCircle(
      Offset(cx.toDouble(), cy.toDouble()),
      (diameter / 2).toDouble(),
      Paint()
        ..color = borderColor
        ..style = PaintStyle.stroke,
    );

    if (selected) {
      canvas.drawCircle(
        Offset(cx.toDouble(), cy.toDouble()),
        (diameter / 3).toDouble(),
        Paint()..color = selectedColor,
      );
    }

    canvas.drawText(
      label,
      Offset((x + diameter + 8).toDouble(), (y + (height - 16) ~/ 2).toDouble()),
      color: textColor,
      size: 16,
    );
  }
}
