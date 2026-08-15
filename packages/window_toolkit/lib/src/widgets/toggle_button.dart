import '../drawing/color.dart';
import '../interaction.dart';
import '../mixins/hoverable.dart';
import '../mixins/hover_animated.dart';
import '../painter/painter.dart';
import '../widget.dart';

class ToggleButton extends Widget with Hoverable, HoverAnimated {
  String label;
  bool selected;
  Color textColor;
  Color selectedColor;
  Color unselectedColor;
  Color borderColor;
  Color hoverColor;
  VoidCallback? onChanged;

  ToggleButton(
    this.label, {
    this.selected = false,
    this.textColor = const Color(255, 255, 255),
    this.selectedColor = const Color(80, 140, 220),
    this.unselectedColor = const Color(50, 50, 50),
    this.borderColor = const Color(70, 70, 70),
    this.hoverColor = const Color(65, 65, 65),
    this.onChanged,
  }) {
    width = label.length * 8 + 16;
    height = 24;
    setInteractionState(WidgetState.selected, selected);
    onClick = () {
      toggle();
      return true;
    };
    tabIndex = 1;
  }

  void toggle() {
    setState(() {
      selected = !selected;
      setInteractionState(WidgetState.selected, selected);
    });
    onChanged?.call();
  }

  @override
  bool get acceptsFocus => true;

  @override
  void draw(Painter canvas) {
    final fill = selected
        ? selectedColor
        : transitionHover(unselectedColor, hoverColor);
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
    canvas.drawText(
      label,
      Offset((x + 8).toDouble(), (y + 4).toDouble()),
      color: textColor,
      size: 16,
    );
  }
}

class SegmentedControl extends Widget with Hoverable, HoverAnimated {
  List<String> labels;
  int selectedIndex;
  Color textColor;
  Color selectedColor;
  Color unselectedColor;
  Color borderColor;
  VoidCallback? onChanged;
  int _hoverIndex = -1;

  SegmentedControl({
    this.labels = const [],
    this.selectedIndex = 0,
    this.textColor = const Color(255, 255, 255),
    this.selectedColor = const Color(80, 140, 220),
    this.unselectedColor = const Color(45, 45, 45),
    this.borderColor = const Color(70, 70, 70),
    this.onChanged,
  }) {
    height = 24;
    setInteractionState(WidgetState.selected, selectedIndex >= 0);
    onClick = () {
      if (_hoverIndex < 0) return false;
      select(_hoverIndex);
      return true;
    };
  }

  @override
  bool get acceptsFocus => true;

  @override
  void onMouseMove(int x, int y) {
    final next = segmentAt(x, y);
    if (next == _hoverIndex) return;
    setState(() {
      _hoverIndex = next;
      setInteractionState(WidgetState.hovered, next >= 0);
    });
  }

  int get _segmentWidth => labels.isEmpty ? 0 : (width ~/ labels.length);

  @override
  void draw(Painter canvas) {
    if (labels.isEmpty) return;
    final sw = _segmentWidth;

    for (var i = 0; i < labels.length; i++) {
      final sx = x + i * sw;
      final isSelected = i == selectedIndex;
      final isHovered = i == _hoverIndex;
      canvas.drawRect(
        Rect.fromLTWH(
          sx.toDouble(),
          y.toDouble(),
          sw.toDouble(),
          height.toDouble(),
        ),
        Paint()
          ..color = isSelected
              ? selectedColor
              : (isHovered
                    ? Color.blend(
                        unselectedColor,
                        const Color(255, 255, 255, 18),
                      )
                    : unselectedColor),
      );
      canvas.drawRect(
        Rect.fromLTWH(sx.toDouble(), y.toDouble(), sw.toDouble(), 1),
        Paint()..color = borderColor,
      );
      canvas.drawRect(
        Rect.fromLTWH(
          sx.toDouble(),
          (y + height - 1).toDouble(),
          sw.toDouble(),
          1,
        ),
        Paint()..color = borderColor,
      );
      if (i == 0) {
        canvas.drawRect(
          Rect.fromLTWH(sx.toDouble(), y.toDouble(), 1, height.toDouble()),
          Paint()..color = borderColor,
        );
      }
      canvas.drawRect(
        Rect.fromLTWH(
          (sx + sw - 1).toDouble(),
          y.toDouble(),
          1,
          height.toDouble(),
        ),
        Paint()..color = borderColor,
      );
      canvas.drawText(
        labels[i],
        Offset(
          (sx + (sw - labels[i].length * 8) ~/ 2).toDouble(),
          (y + 4).toDouble(),
        ),
        color: textColor,
        size: 16,
      );
    }
  }

  void select(int index) {
    if (index >= 0 && index < labels.length && index != selectedIndex) {
      selectedIndex = index;
      onChanged?.call();
    }
  }

  int segmentAt(int px, int py) {
    if (labels.isEmpty || width <= 0) return -1;
    final sw = _segmentWidth;
    final idx = (px - x) ~/ sw;
    if (idx >= 0 && idx < labels.length && py >= y && py < y + height)
      return idx;
    return -1;
  }
}
