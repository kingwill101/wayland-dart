import '../drawing/color.dart';
import '../interaction.dart';
import '../mixins/hoverable.dart';
import '../mixins/hover_animated.dart';
import '../painter/painter.dart';

import '../widget.dart';

class Slider extends Widget with Hoverable, HoverAnimated {
  double min;
  double max;
  double value;
  int trackHeight;
  int thumbRadius;
  final Color? _trackColor;
  final Color? _fillColor;
  final Color? _thumbColor;
  bool showValue;
  VoidCallback? onChanged;
  bool _dragging = false;

  Slider({
    this.min = 0,
    this.max = 100,
    double value = 0,
    this.trackHeight = 4,
    this.thumbRadius = 8,
    Color? trackColor,
    Color? fillColor,
    Color? thumbColor,
    this.showValue = true,
    this.onChanged,
    WidgetKey? key,
  }) : assert(max > min, 'Slider max must be > min'),
       assert(trackHeight > 0, 'Slider trackHeight must be > 0'),
       assert(thumbRadius > 0, 'Slider thumbRadius must be > 0'),
       value = value.clamp(min, max).toDouble(),
       _trackColor = trackColor,
       _fillColor = fillColor,
       _thumbColor = thumbColor {
    width = 160;
    height = thumbRadius * 2 > trackHeight ? thumbRadius * 2 : trackHeight;
  }

  Color get trackColor => _trackColor ?? palette.mid;
  Color get fillColor => _fillColor ?? palette.highlight;
  Color get thumbColor => _thumbColor ?? palette.light;

  @override
  bool get acceptsFocus => true;

  @override
  void onMouseDown(int x, int y, int button) {
    if (button == 272) {
      setState(() => _dragging = true);
      setInteractionState(WidgetState.dragging, true);
      setFraction((x - this.x) / width);
    }
  }

  @override
  void onMouseDrag(int x, int y) {
    if (_dragging) {
      setFraction((x - this.x) / width);
    }
  }

  @override
  void onMouseUp(int x, int y, int button) {
    setState(() => _dragging = false);
    setInteractionState(WidgetState.dragging, false);
  }

  double get fraction {
    final range = max - min;
    if (range <= 0) return 1;
    return ((value - min) / range).clamp(0.0, 1.0);
  }

  void setValue(double newValue) {
    value = newValue.clamp(min, max).toDouble();
    onChanged?.call();
  }

  void setFraction(double newFraction) {
    final range = max - min;
    if (range <= 0) {
      value = max;
    } else {
      setValue(min + range * newFraction.clamp(0.0, 1.0));
    }
  }

  @override
  void draw(Painter canvas) {
    final valueText = value.round().toString();
    final valueWidth = showValue
        ? canvas.measureText(valueText, size: 16).width.ceil()
        : 0;
    const valueGap = 8;
    final trackWidth = showValue
        ? (width - valueWidth - valueGap).clamp(0, width)
        : width;
    final trackY = y + (height - trackHeight) ~/ 2;
    final thumbCenterY = y + height ~/ 2;
    final fillWidth = (trackWidth * fraction).round();
    final thumb = transitionHover(
      thumbColor,
      Color.blend(thumbColor, const Color(255, 255, 255, 28)),
    );

    canvas.drawRect(
      Rect.fromLTWH(
        x.toDouble(),
        trackY.toDouble(),
        trackWidth.toDouble(),
        trackHeight.toDouble(),
      ),
      Paint()..color = trackColor,
    );

    canvas.drawRect(
      Rect.fromLTWH(
        x.toDouble(),
        trackY.toDouble(),
        fillWidth.toDouble(),
        trackHeight.toDouble(),
      ),
      Paint()..color = fillColor,
    );

    canvas.drawCircle(
      Offset((x + fillWidth).toDouble(), thumbCenterY.toDouble()),
      thumbRadius.toDouble(),
      Paint()
        ..color = _dragging
            ? Color.blend(thumb, const Color(255, 255, 255, 20))
            : thumb,
    );

    if (showValue) {
      canvas.drawText(
        valueText,
        Offset(
          (x + trackWidth + valueGap).toDouble(),
          (y + (height - 16) ~/ 2).toDouble(),
        ),
        size: 16,
      );
    }
  }
}
