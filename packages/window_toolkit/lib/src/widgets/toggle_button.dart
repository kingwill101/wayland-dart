import '../drawing/color.dart';
import '../font/font.dart';
import '../interaction.dart';
import '../mixins/hoverable.dart';
import '../mixins/hover_animated.dart';
import '../painter/painter.dart';
import '../style.dart';
import '../style/style_patch.dart';
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
  Style styleRole() => Style(
    color: textColor,
    backgroundColor: selected ? selectedColor : unselectedColor,
    borderColor: borderColor,
  );

  @override
  void draw(Painter canvas) {
    final base = resolvedStyle();
    final hover = resolvedStyleOn(const [
      'hover',
    ], local: StylePatch(backgroundColor: hoverColor));
    final fill = transitionHover(base.backgroundColor!, hover.backgroundColor!);
    drawStyledBox(
      canvas,
      style: base.overlay(StylePatch(backgroundColor: fill)),
    );
    drawStyledText(
      canvas,
      label,
      Offset(
        (x + styledPaddingLeft(8)).toDouble(),
        (y + styledPaddingTop(4)).toDouble(),
      ),
      style: base,
      color: base.color,
      fallback: const Font(pixelSize: 16),
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
  Style styleRole() => Style(
    color: textColor,
    backgroundColor: unselectedColor,
    borderColor: borderColor,
  );

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
    final base = resolvedStyle();

    for (var i = 0; i < labels.length; i++) {
      final sx = x + i * sw;
      final isSelected = i == selectedIndex;
      final isHovered = i == _hoverIndex;
      final segmentColor = isSelected
          ? selectedColor
          : (isHovered
                ? Color.blend(
                    base.backgroundColor!,
                    const Color(255, 255, 255, 18),
                  )
                : base.backgroundColor!);
      final segment = base.overlay(StylePatch(backgroundColor: segmentColor));
      final segmentRect = Rect.fromLTWH(
        sx.toDouble(),
        y.toDouble(),
        sw.toDouble(),
        height.toDouble(),
      );
      drawStyledRect(canvas, segmentRect, style: segment);
      drawStyledText(
        canvas,
        labels[i],
        Offset(
          (sx + (sw - labels[i].length * 8) ~/ 2).toDouble(),
          (y + 4).toDouble(),
        ),
        style: base,
        color: base.color,
        fallback: const Font(pixelSize: 16),
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
