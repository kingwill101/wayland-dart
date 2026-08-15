import '../drawing/color.dart';
import '../painter/painter.dart';
import '../widget.dart';

/// A compact line graph for time-series values.
///
/// The widget owns geometry and drawing; callers only replace [values] and
/// request a repaint when a new sample arrives.
class Sparkline extends Widget {
  List<double> values;
  Color lineColor;
  Color? backgroundColor;
  double strokeWidth;
  double? minValue;
  double? maxValue;

  Sparkline({
    this.values = const [],
    required int width,
    required int height,
    this.lineColor = const Color(136, 192, 208),
    this.backgroundColor,
    this.strokeWidth = 1.5,
    this.minValue,
    this.maxValue,
  }) : assert(width > 0, 'Sparkline width must be > 0'),
       assert(height > 0, 'Sparkline height must be > 0') {
    this.width = width;
    this.height = height;
  }

  @override
  void measure(Painter painter) {
    // Width and height are intrinsic; this widget must not expand to a bar
    // section's available width.
  }

  @override
  void draw(Painter canvas) {
    if (backgroundColor != null) {
      canvas.drawRect(
        Rect.fromLTWH(
          x.toDouble(),
          y.toDouble(),
          width.toDouble(),
          height.toDouble(),
        ),
        Paint()..color = backgroundColor!,
      );
    }
    if (values.length < 2) return;

    final low = minValue ?? values.reduce((a, b) => a < b ? a : b);
    final high = maxValue ?? values.reduce((a, b) => a > b ? a : b);
    final range = (high - low).abs();
    final paint = Paint()
      ..color = lineColor
      ..style = PaintStyle.stroke
      ..strokeWidth = strokeWidth;
    final divisor = (values.length - 1).toDouble();
    final valueRange = range < 0.0001 ? 1.0 : range;

    for (var i = 1; i < values.length; i++) {
      final x1 = x + (i - 1) / divisor * (width - 1);
      final x2 = x + i / divisor * (width - 1);
      final y1 =
          y + height - 1 - ((values[i - 1] - low) / valueRange) * (height - 1);
      final y2 =
          y + height - 1 - ((values[i] - low) / valueRange) * (height - 1);
      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paint);
    }
  }
}
