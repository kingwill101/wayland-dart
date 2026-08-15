import '../drawing/color.dart';
import '../font/font.dart';
import '../painter/painter.dart';
import '../style.dart';
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
  }) : assert(barWidth > 0, 'ProgressBar barWidth must be > 0'),
       assert(barHeight > 0, 'ProgressBar barHeight must be > 0'),
       assert(max > min, 'ProgressBar max must be > min') {
    const charHeight = 16;
    width = barWidth;
    height = showText
        ? (barHeight > charHeight ? barHeight : charHeight)
        : barHeight;
  }

  @override
  Style styleRole() => Style(
    color: fillColor,
    backgroundColor: backgroundColor,
    borderColor: backgroundColor,
    borderWidth: 0,
  );

  @override
  void draw(Painter canvas) {
    final style = resolvedStyle();
    final clampedValue = value.clamp(min, max);
    final range = max - min;

    drawStyledBox(canvas, style: style);

    if (range > 0 && clampedValue > min) {
      final fillWidth = ((clampedValue - min) * width ~/ range);
      final fillRect = Rect.fromLTWH(
        x.toDouble(),
        y.toDouble(),
        fillWidth.toDouble(),
        height.toDouble(),
      );
      if (style.borderRadius > 0) {
        canvas.drawRRect(
          fillRect,
          style.borderRadius,
          style.borderRadius,
          Paint()..color = styledColor(style.color, style),
        );
      } else {
        canvas.drawRect(
          fillRect,
          Paint()..color = styledColor(style.color, style),
        );
      }
    }

    if (showText) {
      const charHeight = 16;
      final percentage = range > 0
          ? ((clampedValue - min) * 100 ~/ range)
          : 100;
      final text = '$percentage%';
      final textX = x + (width - text.length * 8) ~/ 2;
      final textY = y + (height - charHeight) ~/ 2;
      drawStyledText(
        canvas,
        text,
        Offset(textX.toDouble(), textY.toDouble()),
        style: style,
        color: style.color,
        fallback: Font(pixelSize: charHeight.toDouble()),
      );
    }
  }
}
