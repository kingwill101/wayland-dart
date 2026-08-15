import '../drawing/color.dart';
import '../painter/painter.dart';
import '../style.dart';
import '../widget.dart';

class Badge extends Widget {
  String? label;
  int count;
  Color backgroundColor;
  Color textColor;
  Color borderColor;
  int padding;
  int minSize;
  bool showZero;

  Badge({
    this.label,
    this.count = 0,
    this.backgroundColor = const Color(200, 60, 60),
    this.textColor = const Color(255, 255, 255),
    this.borderColor = const Color(30, 30, 30),
    this.padding = 4,
    this.minSize = 8,
    this.showZero = false,
  }) : assert(padding >= 0, 'Badge padding must be >= 0'),
       assert(minSize > 0, 'Badge minSize must be > 0') {
    final text = label ?? (count.toString());
    width = text.length * 8 + padding * 2;
    if (width < minSize) width = minSize;
    height = 16;
  }

  @override
  Style styleRole() => Style(
    color: textColor,
    backgroundColor: backgroundColor,
    borderColor: borderColor,
    borderRadius: 99,
  );

  @override
  void draw(Painter canvas) {
    final text = label ?? (showZero || count > 0 ? count.toString() : null);
    if (text == null) return;

    final style = resolvedStyle();
    canvas.drawCircle(
      Offset((x + width ~/ 2).toDouble(), (y + height ~/ 2).toDouble()),
      (height / 2).toDouble(),
      Paint()..color = style.backgroundColor!,
    );
    canvas.drawCircle(
      Offset((x + width ~/ 2).toDouble(), (y + height ~/ 2).toDouble()),
      (height / 2).toDouble(),
      Paint()
        ..color = style.borderColor
        ..style = PaintStyle.stroke
        ..strokeWidth = 1,
    );

    canvas.drawText(
      text,
      Offset(
        (x + (width - text.length * 8) ~/ 2).toDouble(),
        (y + 1).toDouble(),
      ),
      color: style.color,
      size: 12,
    );
  }
}
