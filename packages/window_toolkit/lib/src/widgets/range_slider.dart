import '../drawing/color.dart';
import '../painter/painter.dart';
import '../widget.dart';

class RangeSlider extends Widget {
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

  final bool _draggingLower = false;
  final bool _draggingUpper = false;

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
  })  : assert(max > min, 'RangeSlider max must be > min'),
        lower = lower.clamp(min, max),
        upper = upper.clamp(min, max) {
    width = 160;
    height = thumbRadius * 2 > trackHeight ? thumbRadius * 2 : trackHeight;
  }

  double get _range => max - min;
  double get _lowerFraction => _range <= 0 ? 0 : ((lower - min) / _range).clamp(0.0, 1.0);
  double get _upperFraction => _range <= 0 ? 1 : ((upper - min) / _range).clamp(0.0, 1.0);



  @override
  void draw(Painter canvas) {
    final trackY = y + (height - trackHeight) ~/ 2;
    final cy = y + height ~/ 2;
    final lx = (x + (width * _lowerFraction).round()).toDouble();
    final ux = (x + (width * _upperFraction).round()).toDouble();

    canvas.drawRect(
      Rect.fromLTWH(x.toDouble(), trackY.toDouble(), width.toDouble(), trackHeight.toDouble()),
      Paint()..color = trackColor,
    );
    canvas.drawRect(
      Rect.fromLTWH(lx, trackY.toDouble(), (ux - lx).toDouble(), trackHeight.toDouble()),
      Paint()..color = fillColor,
    );

    canvas.drawCircle(Offset(lx, cy.toDouble()), thumbRadius.toDouble(),
      Paint()..color = _draggingLower ? activeThumbColor : thumbColor);
    canvas.drawCircle(Offset(ux, cy.toDouble()), thumbRadius.toDouble(),
      Paint()..color = _draggingUpper ? activeThumbColor : thumbColor);
  }
}
