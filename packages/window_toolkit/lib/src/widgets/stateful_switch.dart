/// Stateful Switch with Element tree lifecycle.
///
/// Unlike the plain [Switch], this version uses [StatefulWidget] with
/// proper `initState()`, `dispose()`, and `setState()` lifecycle.
///
/// Use with [ElementHost]:
/// ```dart
/// ElementHost(child: StatefulSwitch(value: true))
/// ```
import 'package:layout_engine/layout_engine.dart' show ElementWidget, State, StatefulWidget;

import '../drawing/color.dart';
import '../painter/painter.dart';
import '../widget.dart';

class StatefulSwitch extends StatefulWidget {
  final bool value;
  final void Function(bool)? onChanged;

  StatefulSwitch({this.value = false, this.onChanged});

  @override
  State createState() => _SwitchState();
}

class _SwitchState extends State<StatefulSwitch> {
  late bool _value;
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    _value = widget.value;
  }

  @override
  void didUpdateWidget(covariant StatefulSwitch oldWidget) {
    super.didUpdateWidget(oldWidget);
    _value = widget.value;
  }

  void toggle() {
    setState(() => _value = !_value);
    widget.onChanged?.call(_value);
  }

  @override
  ElementWidget build(BuildContext context) {
    return _SwitchRender(
      value: _value,
      hovered: _hovered,
      onToggle: toggle,
      onHover: (v) => setState(() => _hovered = v),
    );
  }
}

class _SwitchRender extends Widget {
  final bool value;
  final bool hovered;
  final VoidCallback onToggle;
  final void Function(bool) onHover;

  _SwitchRender({
    required this.value,
    required this.hovered,
    required this.onToggle,
    required this.onHover,
  }) {
    onClick = () { onToggle(); return true; };
    onMouseEnter = () => setState(() => onHover(true));
    onMouseLeave = () => setState(() => onHover(false));
    width = 42;
    height = 22;
  }

  @override
  void draw(Painter canvas) {
    final trackColor = value ? const Color(0, 180, 80) : palette.mid;
    final fill = hovered
        ? Color.blend(trackColor, const Color(255, 255, 255, 24))
        : trackColor;

    canvas.drawRect(
      Rect.fromLTWH(x.toDouble(), y.toDouble(), width.toDouble(), height.toDouble()),
      Paint()..color = fill,
    );
    canvas.drawRect(
      Rect.fromLTWH(x.toDouble(), y.toDouble(), width.toDouble(), 1),
      Paint()..color = palette.shadow,
    );
    canvas.drawRect(
      Rect.fromLTWH(x.toDouble(), (y + height - 1).toDouble(), width.toDouble(), 1),
      Paint()..color = palette.shadow,
    );

    final knobRadius = (height / 2) - 2;
    final knobCenterX = value ? x + width - height ~/ 2 : x + height ~/ 2;
    final knobCenterY = y + height ~/ 2;
    canvas.drawCircle(
      Offset(knobCenterX.toDouble(), knobCenterY.toDouble()),
      knobRadius.toDouble(),
      Paint()..color = palette.light,
    );
  }

  @override
  void performLayout(int containerWidth) {
    width = containerWidth > 0 ? containerWidth : 42;
    height = 22;
  }

  @override
  bool hitTest(int px, int py) => super.hitTest(px, py);
}
