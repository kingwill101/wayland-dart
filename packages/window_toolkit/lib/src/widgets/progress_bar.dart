import '../drawing/color.dart';
import '../painter/painter.dart';
import '../widget.dart';

class ProgressBar extends Widget {
  int value;
  int min;
  int max;
  int barWidth;
  int barHeight;
  Color fillColor;
  Color backgroundColor;
  bool showText;

  ProgressBar({
    this.value = 0,
    this.min = 0,
    this.max = 100,
    required this.barWidth,
    this.barHeight = 16,
    this.fillColor = const Color(100, 200, 100),
    this.backgroundColor = const Color(50, 50, 50),
    this.showText = true,
  }) {
    const charHeight = 16;
    width = barWidth;
    height = showText ? (barHeight > charHeight ? barHeight : charHeight) : barHeight;
  }

  @override
  void draw(Painter canvas) {
    final clampedValue = value.clamp(min, max);
    final range = max - min;

    canvas.drawRect(
        Rect.fromLTWH(x.toDouble(), y.toDouble(), width.toDouble(),
            height.toDouble()),
        Paint()..color = backgroundColor);

    if (range > 0 && clampedValue > min) {
      final fillWidth = ((clampedValue - min) * width ~/ range);
      canvas.drawRect(
          Rect.fromLTWH(x.toDouble(), y.toDouble(), fillWidth.toDouble(),
              height.toDouble()),
          Paint()..color = fillColor);
    }

    if (showText) {
      const charHeight = 16;
      final percentage = range > 0 ? ((clampedValue - min) * 100 ~/ range) : 100;
      final text = '$percentage%';
      final textX = x + (width - text.length * 8) ~/ 2;
      final textY = y + (height - charHeight) ~/ 2;
      canvas.drawText(text, Offset(textX.toDouble(), textY.toDouble()),
          size: charHeight.toDouble());
    }
  }
}
