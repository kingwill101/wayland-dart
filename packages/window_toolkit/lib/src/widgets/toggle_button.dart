import '../drawing/color.dart';
import '../painter/painter.dart';
import '../widget.dart';

class ToggleButton extends Widget {
  String label;
  bool selected;
  Color textColor;
  Color selectedColor;
  Color unselectedColor;
  Color borderColor;
  Color hoverColor;
  VoidCallback? onChanged;

  bool _hovered = false;

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
    onClick = () { toggle(); return true; };
    onMouseEnter = () => setState(() => _hovered = true);
    onMouseLeave = () => setState(() => _hovered = false);
  }

  void toggle() {
    setState(() => selected = !selected);
    onChanged?.call();
  }

  @override
  void draw(Painter canvas) {
    final fill = selected ? selectedColor : (_hovered ? hoverColor : unselectedColor);
    canvas.drawRect(
      Rect.fromLTWH(x.toDouble(), y.toDouble(), width.toDouble(), height.toDouble()),
      Paint()..color = fill,
    );
    canvas.drawRect(
      Rect.fromLTWH(x.toDouble(), y.toDouble(), width.toDouble(), 1),
      Paint()..color = borderColor,
    );
    canvas.drawRect(
      Rect.fromLTWH(x.toDouble(), (y + height - 1).toDouble(), width.toDouble(), 1),
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

class SegmentedControl extends Widget {
  List<String> labels;
  int selectedIndex;
  Color textColor;
  Color selectedColor;
  Color unselectedColor;
  Color borderColor;
  VoidCallback? onChanged;

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
  }

  int get _segmentWidth => labels.isEmpty ? 0 : (width ~/ labels.length);

  @override
  void draw(Painter canvas) {
    if (labels.isEmpty) return;
    final sw = _segmentWidth;

    for (var i = 0; i < labels.length; i++) {
      final sx = x + i * sw;
      final isSelected = i == selectedIndex;
      canvas.drawRect(
        Rect.fromLTWH(sx.toDouble(), y.toDouble(), sw.toDouble(), height.toDouble()),
        Paint()..color = isSelected ? selectedColor : unselectedColor,
      );
      canvas.drawRect(
        Rect.fromLTWH(sx.toDouble(), y.toDouble(), sw.toDouble(), 1),
        Paint()..color = borderColor,
      );
      canvas.drawRect(
        Rect.fromLTWH(sx.toDouble(), (y + height - 1).toDouble(), sw.toDouble(), 1),
        Paint()..color = borderColor,
      );
      if (i == 0) {
        canvas.drawRect(
          Rect.fromLTWH(sx.toDouble(), y.toDouble(), 1, height.toDouble()),
          Paint()..color = borderColor,
        );
      }
      canvas.drawRect(
        Rect.fromLTWH((sx + sw - 1).toDouble(), y.toDouble(), 1, height.toDouble()),
        Paint()..color = borderColor,
      );
      canvas.drawText(
        labels[i],
        Offset((sx + (sw - labels[i].length * 8) ~/ 2).toDouble(), (y + 4).toDouble()),
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
    if (idx >= 0 && idx < labels.length && py >= y && py < y + height) return idx;
    return -1;
  }
}
