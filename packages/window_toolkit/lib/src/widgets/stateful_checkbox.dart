/// Stateful checkbox with lifecycle management via Element tree.
///
/// Unlike the plain [Checkbox], this version uses [StatefulWidget] with
/// proper `setState()`, `initState()`, and `dispose()` lifecycle.
///
/// Use inside containers with [autoElement] or [ElementHost]:
/// ```dart
/// VBox(children: [
///   ElementHost(child: StatefulCheckbox(label: 'Option')),
/// ])
/// ```
library;

import '../painter/painter.dart';
import '../widget.dart';
import 'label.dart';

/// Stateful checkbox with Element tree lifecycle.
class StatefulCheckbox extends StatefulWidget {
  final String label;
  final bool initialChecked;
  final void Function(bool)? onChanged;

  StatefulCheckbox({
    this.label = '',
    this.initialChecked = false,
    this.onChanged,
  });

  @override
  State createState() => _CheckboxState();
}

class _CheckboxState extends State<StatefulCheckbox> {
  late bool _checked;

  @override
  void initState() {
    super.initState();
    _checked = widget.initialChecked;
  }

  void _toggle() {
    setState(() {
      _checked = !_checked;
    });
    widget.onChanged?.call(_checked);
  }

  @override
  ElementWidget build(BuildContext context) {
    return _CheckboxRender(
      checked: _checked,
      onToggle: _toggle,
      label: widget.label,
    );
  }
}

/// Rendering widget for the stateful checkbox.
class _CheckboxRender extends Widget {
  final bool checked;
  final VoidCallback onToggle;
  final String label;
  static const int boxSize = 18;

  _CheckboxRender({
    required this.checked,
    required this.onToggle,
    this.label = '',
  }) {
    tabIndex = 1;
    onClick = () { onToggle(); return true; };
  }

  @override
  void draw(Painter canvas) {
    final outer = Rect.fromLTWH(x.toDouble(), y.toDouble(), boxSize.toDouble(), boxSize.toDouble());
    canvas.drawRect(outer, Paint()..color = palette.base);
    canvas.drawRect(Rect.fromLTWH(x.toDouble(), y.toDouble(), boxSize.toDouble(), 1),
        Paint()..color = palette.mid);
    canvas.drawRect(Rect.fromLTWH(x.toDouble(), (y + boxSize - 1).toDouble(), boxSize.toDouble(), 1),
        Paint()..color = palette.mid);
    canvas.drawRect(Rect.fromLTWH(x.toDouble(), y.toDouble(), 1, boxSize.toDouble()),
        Paint()..color = palette.mid);
    canvas.drawRect(Rect.fromLTWH((x + boxSize - 1).toDouble(), y.toDouble(), 1, boxSize.toDouble()),
        Paint()..color = palette.mid);

    if (checked) {
      final p = Paint()..color = palette.text..strokeWidth = 2;
      canvas.drawLine(
        Offset((x + boxSize * 0.22).toDouble(), (y + boxSize * 0.55).toDouble()),
        Offset((x + boxSize * 0.42).toDouble(), (y + boxSize * 0.75).toDouble()), p);
      canvas.drawLine(
        Offset((x + boxSize * 0.40).toDouble(), (y + boxSize * 0.74).toDouble()),
        Offset((x + boxSize * 0.78).toDouble(), (y + boxSize * 0.28).toDouble()), p);
    }

    if (label.isNotEmpty) {
      final lbl = Label(label);
      lbl.x = x + boxSize + 4;
      lbl.y = y;
      lbl.draw(canvas);
    }
  }

  @override
  void performLayout(int containerWidth) {
    width = containerWidth;
    height = boxSize;
  }

}
