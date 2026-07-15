import '../drawing/color.dart';
import '../painter/painter.dart';
import '../widget.dart';

class Checkbox extends Widget {
  bool checked;
  Color? _boxColor;
  Color? _borderColor;
  Color? _checkColor;
  int boxSize;
  VoidCallback? onChanged;

  Checkbox({
    this.checked = false,
    Color? boxColor,
    Color? borderColor,
    Color? checkColor,
    this.boxSize = 18,
    this.onChanged,
  })  : assert(boxSize > 0, 'Checkbox boxSize must be > 0'),
        _boxColor = boxColor,
        _borderColor = borderColor,
        _checkColor = checkColor {
    width = boxSize;
    height = boxSize;
    onClick = toggle;
  }

  Color get boxColor => _boxColor ?? palette.base;
  Color get borderColor => _borderColor ?? palette.mid;
  Color get checkColor => _checkColor ?? palette.text;

  void toggle() {
    checked = !checked;
    onChanged?.call();
  }

  @override
  void draw(Painter canvas) {
    final outer = Rect.fromLTWH(
      x.toDouble(),
      y.toDouble(),
      width.toDouble(),
      height.toDouble(),
    );
    canvas.drawRect(outer, Paint()..color = boxColor);

    canvas.drawRect(
      Rect.fromLTWH(x.toDouble(), y.toDouble(), width.toDouble(), 1),
      Paint()..color = borderColor,
    );
    canvas.drawRect(
      Rect.fromLTWH(x.toDouble(), (y + height - 1).toDouble(), width.toDouble(), 1),
      Paint()..color = borderColor,
    );
    canvas.drawRect(
      Rect.fromLTWH(x.toDouble(), y.toDouble(), 1, height.toDouble()),
      Paint()..color = borderColor,
    );
    canvas.drawRect(
      Rect.fromLTWH((x + width - 1).toDouble(), y.toDouble(), 1, height.toDouble()),
      Paint()..color = borderColor,
    );

    if (checked) {
      final checkPaint = Paint()
        ..color = checkColor
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
