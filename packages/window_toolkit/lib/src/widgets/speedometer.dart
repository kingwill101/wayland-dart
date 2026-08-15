import 'dart:math';

import 'package:window_toolkit/window_toolkit.dart';

/// A fixed-size speedometer gauge.
///
/// Draws a 270° arc (open at the bottom), tick marks, a needle, and
/// a centered value/label. [value] is 0..1; [maxValue] is used only
/// for formatting the displayed text.
class Speedometer extends Widget {
  double value;
  String label;
  String? valueText;
  final Color trackColor;
  Color fillColor;
  final Color needleColor;
  final Color textColor;
  double maxValue;
  final int decimals;

  Speedometer({
    super.key,
    this.value = 0.0,
    this.label = '',
    this.valueText,
    this.trackColor = const Color(50, 50, 60),
    this.fillColor = const Color(0, 160, 255),
    this.needleColor = const Color(235, 235, 240),
    this.textColor = const Color(235, 235, 240),
    this.maxValue = 100.0,
    this.decimals = 1,
  });

  static const preferredWidth = 340;
  static const preferredHeight = 220;

  @override
  double measure(Painter painter) {
    width = preferredWidth;
    height = preferredHeight;
    return preferredWidth.toDouble();
  }

  @override
  void performLayout(int containerWidth) {
    width = containerWidth > 0 ? containerWidth : preferredWidth;
    height = preferredHeight;
  }

  @override
  void draw(Painter canvas) {
    final painter = canvas;
    final x = this.x.toDouble();
    final y = this.y.toDouble();
    final w = (width > 0 ? width : preferredWidth).toDouble();
    final h = (height > 0 ? height : preferredHeight).toDouble();
    this.width = w.round();
    this.height = h.round();

    final cx = x + w / 2;
    final cy = y + h * 0.40;
    final r = min(w * 0.27, h * 0.38);

    final startAngle = 150 * pi / 180;
    final sweepAngle = 240 * pi / 180;
    const useCenter = false;
    final oval = Rect.fromLTWH(cx - r, cy - r, r * 2, r * 2);
    final fill = value.clamp(0.0, 1.0);

    // Track arc.
    painter.drawArc(
      oval,
      startAngle,
      sweepAngle,
      useCenter,
      Paint()
        ..color = trackColor
        ..style = PaintStyle.stroke
        ..strokeWidth = 16,
    );

    // Fill arc. Painter gradients cannot be applied directly to an arc, so
    // use short, smoothly changing segments for the same visual effect.
    if (fill > 0.002) {
      const segments = 24;
      final filledSegments = (fill * segments).ceil();
      for (var i = 0; i < filledSegments; i++) {
        final t = i / (segments - 1);
        final segmentStart = startAngle + i / segments * sweepAngle;
        final segmentSweep = sweepAngle / segments * 0.94;
        painter.drawArc(
          oval,
          segmentStart,
          segmentSweep,
          useCenter,
          Paint()
            ..color = _lerpColor(const Color(42, 207, 255), fillColor, t)
            ..style = PaintStyle.stroke
            ..strokeWidth = 16,
        );
      }
    }

    // Tick marks.
    for (int i = 0; i <= 10; i++) {
      final frac = i / 10.0;
      final angle = startAngle + frac * sweepAngle;
      final isMajor = i % 5 == 0;
      final innerR = r - (isMajor ? 22 : 15);
      final outerR = r - 8;
      painter.drawLine(
        Offset(cx + innerR * cos(angle), cy + innerR * sin(angle)),
        Offset(cx + outerR * cos(angle), cy + outerR * sin(angle)),
        Paint()
          ..color = Color(
            textColor.r.toInt(),
            textColor.g.toInt(),
            textColor.b.toInt(),
            isMajor ? 200 : 90,
          )
          ..strokeWidth = isMajor ? 2.5 : 1.2,
      );
    }

    // Sparse scale labels give the dial a useful hierarchy without making
    // the compact popup feel crowded.
    final scaleValues = <double>[0, maxValue / 2, maxValue];
    for (var i = 0; i < scaleValues.length; i++) {
      final angle = startAngle + i / 2 * sweepAngle;
      final text = scaleValues[i].round().toString();
      final bounds = painter.measureTextBounds(
        text,
        size: 11,
        fontFamily: 'sans',
      );
      final labelR = r - 34;
      painter.drawText(
        text,
        Offset(
          cx + labelR * cos(angle) - bounds.width / 2,
          cy + labelR * sin(angle) - bounds.height / 2,
        ),
        color: Color(
          textColor.r.toInt(),
          textColor.g.toInt(),
          textColor.b.toInt(),
          190,
        ),
        size: 11,
      );
    }

    // Let the needle extend beyond the value card so live movement remains
    // visible while the card keeps the numeric readout legible at the pivot.
    final needleAngle = startAngle + fill * sweepAngle;
    final needleLen = r - 8;
    painter.drawLine(
      Offset(cx, cy),
      Offset(
        cx + needleLen * cos(needleAngle),
        cy + needleLen * sin(needleAngle),
      ),
      Paint()
        ..color = Color(0, 0, 0, 150)
        ..strokeWidth = 7,
    );
    painter.drawLine(
      Offset(cx, cy),
      Offset(
        cx + needleLen * cos(needleAngle),
        cy + needleLen * sin(needleAngle),
      ),
      Paint()
        ..color = needleColor
        ..strokeWidth = 3,
    );

    // Center cap.
    painter.drawCircle(Offset(cx, cy), 11, Paint()..color = needleColor);
    painter.drawCircle(Offset(cx, cy), 7, Paint()..color = trackColor);

    // Put the readout below the dial, where it cannot obscure the needle or
    // scale marks.
    final valueSize = 24.0;
    final displayValue = valueText ?? _formatValue(value * maxValue);
    final valueBounds = painter.measureTextBounds(
      displayValue,
      size: valueSize,
      fontFamily: 'sans',
    );
    painter.drawText(
      displayValue,
      Offset(cx - valueBounds.width / 2, y + h - 47),
      color: textColor,
      size: valueSize,
    );

    // Label.
    if (label.isNotEmpty) {
      final labelBounds = painter.measureTextBounds(
        label,
        size: 14,
        fontFamily: 'sans',
      );
      painter.drawText(
        label,
        Offset(cx - labelBounds.width / 2, y + h - 19),
        color: Color(
          textColor.r.toInt(),
          textColor.g.toInt(),
          textColor.b.toInt(),
          160,
        ),
        size: 14,
      );
    }
  }

  Color _lerpColor(Color a, Color b, double t) {
    int channel(int x, int y) => (x + (y - x) * t).round().clamp(0, 255);
    return Color(
      channel(a.r.toInt(), b.r.toInt()),
      channel(a.g.toInt(), b.g.toInt()),
      channel(a.b.toInt(), b.b.toInt()),
      channel(a.a.toInt(), b.a.toInt()),
    );
  }

  String _formatValue(double v) {
    if (v >= 1000 * 1000)
      return '${(v / 1000 / 1000).toStringAsFixed(decimals)} GB/s';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(decimals)} MB/s';
    if (v >= 1) return '${v.toStringAsFixed(decimals)} MB/s';
    return '${(v * 1000).toInt()} KB/s';
  }
}
