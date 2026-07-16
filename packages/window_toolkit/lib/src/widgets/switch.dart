import '../drawing/color.dart';
import '../painter/painter.dart';
import '../widget.dart';

class Switch extends Widget {
  bool value;
  Color? _trackOnColor;
  Color? _trackOffColor;
  Color? _thumbColor;
  Color? _borderColor;
  int trackWidth;
  int trackHeight;
  VoidCallback? onChanged;

  bool _hovered = false;

  Switch({
    this.value = false,
    Color? trackOnColor,
    Color? trackOffColor,
    Color? thumbColor,
    Color? borderColor,
    this.trackWidth = 42,
    this.trackHeight = 22,
    this.onChanged,
  })  : assert(trackWidth > 0, 'Switch trackWidth must be > 0'),
        assert(trackHeight > 0, 'Switch trackHeight must be > 0'),
        _trackOnColor = trackOnColor,
        _trackOffColor = trackOffColor,
        _thumbColor = thumbColor,
        _borderColor = borderColor {
    width = trackWidth;
    height = trackHeight;
    onClick = () { toggle(); return true; };
    onMouseEnter = () => setState(() => _hovered = true);
    onMouseLeave = () => setState(() => _hovered = false);
  }

  Color get trackOnColor => _trackOnColor ?? palette.success;
  Color get trackOffColor => _trackOffColor ?? palette.mid;
  Color get thumbColor => _thumbColor ?? palette.light;
  Color get borderColor => _borderColor ?? palette.shadow;

  void toggle() {
    setState(() => value = !value);
    onChanged?.call();
  }

  @override
  void draw(Painter canvas) {
    final trackColor = value ? trackOnColor : trackOffColor;
    final fill = _hovered
        ? Color.blend(trackColor, const Color(255, 255, 255, 24))
        : trackColor;

    canvas.drawRect(
      Rect.fromLTWH(
        x.toDouble(),
        y.toDouble(),
        width.toDouble(),
        height.toDouble(),
      ),
      Paint()..color = fill,
    );

    canvas.drawRect(
      Rect.fromLTWH(x.toDouble(), y.toDouble(), width.toDouble(), 1),
      Paint()..color = borderColor,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        x.toDouble(),
        (y + height - 1).toDouble(),
        width.toDouble(),
        1,
      ),
      Paint()..color = borderColor,
    );

    final knobRadius = (height / 2) - 2;
    final knobCenterX = value ? x + width - height ~/ 2 : x + height ~/ 2;
    final knobCenterY = y + height ~/ 2;
    canvas.drawCircle(
      Offset(knobCenterX.toDouble(), knobCenterY.toDouble()),
      knobRadius.toDouble(),
      Paint()..color = thumbColor,
    );
  }
}
