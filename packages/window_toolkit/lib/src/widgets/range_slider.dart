import '../drawing/color.dart';
import '../interaction.dart';
import '../mixins/hoverable.dart';
import '../mixins/hover_animated.dart';
import '../painter/painter.dart';
import '../style.dart';
import '../widget.dart';

class RangeSlider extends Widget with Hoverable, HoverAnimated {
  double min;
  double max;
  double lower;
  double upper;
  int trackHeight;
  int thumbRadius;
  Color trackColor;
  Color fillColor;
  Color thumbColor;
  Color activeThumbColor;
  VoidCallback? onChanged;

  bool _draggingLower = false;
  bool _draggingUpper = false;

  RangeSlider({
    this.min = 0,
    this.max = 100,
    double lower = 25,
    double upper = 75,
    this.trackHeight = 4,
    this.thumbRadius = 8,
    this.trackColor = const Color(70, 70, 70),
    this.fillColor = const Color(180, 180, 180),
    this.thumbColor = const Color(240, 240, 240),
    this.activeThumbColor = const Color(255, 255, 255),
    this.onChanged,
  }) : assert(max > min, 'RangeSlider max must be > min'),
       lower = lower.clamp(min, max),
       upper = upper.clamp(min, max) {
    width = 160;
    height = thumbRadius * 2 > trackHeight ? thumbRadius * 2 : trackHeight;
  }

  double get _range => max - min;
  double get _lowerFraction =>
      _range <= 0 ? 0 : ((lower - min) / _range).clamp(0.0, 1.0);
  double get _upperFraction =>
      _range <= 0 ? 1 : ((upper - min) / _range).clamp(0.0, 1.0);

  @override
  bool get acceptsFocus => true;

  @override
  Style styleRole() => Style(
    color: fillColor,
    backgroundColor: trackColor,
    borderColor: thumbColor,
    borderWidth: 0,
    borderRadius: thumbRadius.toDouble(),
  );

  @override
  void onMouseDown(int x, int y, int button) {
    if (button != 272 || width <= 0) return;
    final fraction = ((x - this.x) / width).clamp(0.0, 1.0);
    final valueAtPointer = min + _range * fraction;
    if ((valueAtPointer - lower).abs() <= (valueAtPointer - upper).abs()) {
      _draggingLower = true;
    } else {
      _draggingUpper = true;
    }
    setInteractionState(WidgetState.dragging, true);
    _updateFromPointer(x);
  }

  @override
  void onMouseDrag(int x, int y) {
    if (_draggingLower || _draggingUpper) _updateFromPointer(x);
  }

  @override
  void onMouseUp(int x, int y, int button) {
    _draggingLower = false;
    _draggingUpper = false;
    setInteractionState(WidgetState.dragging, false);
  }

  void _updateFromPointer(int px) {
    final value = min + _range * ((px - x) / width).clamp(0.0, 1.0);
    if (_draggingLower) {
      lower = value.clamp(min, upper);
    } else if (_draggingUpper) {
      upper = value.clamp(lower, max);
    }
    onChanged?.call();
    requestRepaint();
  }

  @override
  void draw(Painter canvas) {
    final style = resolvedStyle();
    final trackY = y + (height - trackHeight) ~/ 2;
    final cy = y + height ~/ 2;
    final lx = (x + (width * _lowerFraction).round()).toDouble();
    final ux = (x + (width * _upperFraction).round()).toDouble();

    final track = Rect.fromLTWH(
      x.toDouble(),
      trackY.toDouble(),
      width.toDouble(),
      trackHeight.toDouble(),
    );
    final filled = Rect.fromLTWH(
      lx,
      trackY.toDouble(),
      (ux - lx).toDouble(),
      trackHeight.toDouble(),
    );
    canvas.drawRRect(
      track,
      style.borderRadius,
      style.borderRadius,
      Paint()..color = styledColor(style.backgroundColor!, style),
    );
    canvas.drawRRect(
      filled,
      style.borderRadius,
      style.borderRadius,
      Paint()..color = styledColor(style.color, style),
    );

    final hoveredThumb = transitionHover(
      style.borderColor,
      Color.blend(style.borderColor, const Color(255, 255, 255, 28)),
    );
    canvas.drawCircle(
      Offset(lx, cy.toDouble()),
      thumbRadius.toDouble(),
      Paint()
        ..color = styledColor(
          _draggingLower ? style.color : hoveredThumb,
          style,
        ),
    );
    canvas.drawCircle(
      Offset(ux, cy.toDouble()),
      thumbRadius.toDouble(),
      Paint()
        ..color = styledColor(
          _draggingUpper ? style.color : hoveredThumb,
          style,
        ),
    );
  }
}
