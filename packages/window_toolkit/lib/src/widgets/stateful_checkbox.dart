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
import '../drawing/color.dart';
import '../interaction.dart';
import '../mixins/hoverable.dart';
import '../mixins/hover_animated.dart';
import '../style.dart';
import '../style/style_patch.dart';
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
class _CheckboxRender extends Widget with Hoverable, HoverAnimated {
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
    setInteractionState(WidgetState.checked, checked);
    onClick = () {
      onToggle();
      return true;
    };
  }

  @override
  bool get acceptsFocus => true;

  @override
  Style styleRole() => Style(
    color: palette.text,
    backgroundColor: palette.base,
    borderColor: palette.mid,
    borderRadius: 3,
  );

  @override
  void draw(Painter canvas) {
    final base = resolvedStyle();
    final fill = transitionHover(
      base.backgroundColor!,
      Color.blend(base.backgroundColor!, const Color(255, 255, 255, 18)),
    );
    drawStyledBox(
      canvas,
      style: base.overlay(StylePatch(backgroundColor: fill)),
    );

    if (checked) {
      final p = Paint()
        ..color = styledColor(base.color, base)
        ..strokeWidth = 2;
      canvas.drawLine(
        Offset(
          (x + boxSize * 0.22).toDouble(),
          (y + boxSize * 0.55).toDouble(),
        ),
        Offset(
          (x + boxSize * 0.42).toDouble(),
          (y + boxSize * 0.75).toDouble(),
        ),
        p,
      );
      canvas.drawLine(
        Offset(
          (x + boxSize * 0.40).toDouble(),
          (y + boxSize * 0.74).toDouble(),
        ),
        Offset(
          (x + boxSize * 0.78).toDouble(),
          (y + boxSize * 0.28).toDouble(),
        ),
        p,
      );
    }

    if (label.isNotEmpty) {
      final lbl = Label(label);
      lbl.parent = this;
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
