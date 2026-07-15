import '../drawing/color.dart';
import '../painter/painter.dart';
import '../widget.dart';

class Dropdown extends Widget {
  List<String> items;
  int selectedIndex;
  bool opened;
  Color textColor;
  Color backgroundColor;
  Color hoverColor;
  Color borderColor;
  Color arrowColor;
  int itemHeight;
  int maxVisibleItems;
  VoidCallback? onChanged;

  bool _hovered = false;

  Dropdown({
    this.items = const [],
    this.selectedIndex = -1,
    this.opened = false,
    this.textColor = const Color(255, 255, 255),
    this.backgroundColor = const Color(36, 36, 36),
    this.hoverColor = const Color(60, 60, 60),
    this.borderColor = const Color(80, 80, 80),
    this.arrowColor = const Color(180, 180, 180),
    this.itemHeight = 22,
    this.maxVisibleItems = 8,
    this.onChanged,
  })  : assert(itemHeight > 0, 'Dropdown itemHeight must be > 0'),
        assert(maxVisibleItems > 0, 'Dropdown maxVisibleItems must be > 0') {
    width = 160;
    height = itemHeight;
    onClick = () { opened = !opened; return true; };
    onMouseEnter = () => _hovered = true;
    onMouseLeave = () => _hovered = false;
  }

  String? get selectedLabel =>
      selectedIndex >= 0 && selectedIndex < items.length
          ? items[selectedIndex]
          : null;

  @override
  void draw(Painter canvas) {
    final fill = _hovered ? hoverColor : backgroundColor;
    canvas.drawRect(
      Rect.fromLTWH(x.toDouble(), y.toDouble(), width.toDouble(), height.toDouble()),
      Paint()..color = fill,
    );

    // Bottom border
    canvas.drawRect(
      Rect.fromLTWH(x.toDouble(), (y + height - 1).toDouble(), width.toDouble(), 1),
      Paint()..color = borderColor,
    );

    // Arrow
    final arrowX = x + width - 14;
    final arrowY = y + height ~/ 2;
    final arrowPaint = Paint()..color = arrowColor;
    canvas.drawLine(
      Offset(arrowX.toDouble(), (arrowY - 2).toDouble()),
      Offset((arrowX + 6).toDouble(), (arrowY - 2).toDouble()),
      arrowPaint,
    );
    canvas.drawLine(
      Offset(arrowX.toDouble(), (arrowY + 2).toDouble()),
      Offset((arrowX + 6).toDouble(), (arrowY + 2).toDouble()),
      arrowPaint,
    );

    // Selected label
    if (selectedLabel != null) {
      canvas.drawText(
        selectedLabel!,
        Offset((x + 6).toDouble(), (y + 3).toDouble()),
        color: textColor,
        size: 16,
      );
    }

    // Dropdown list
    if (opened && items.isNotEmpty) {
      final listH = (items.length < maxVisibleItems ? items.length : maxVisibleItems) * itemHeight;
      final listY = y + height;

      canvas.drawRect(
        Rect.fromLTWH(x.toDouble(), listY.toDouble(), width.toDouble(), listH.toDouble()),
        Paint()..color = const Color(40, 40, 40),
      );

      final visible = items.length < maxVisibleItems
          ? items
          : items.sublist(0, maxVisibleItems);
      for (var i = 0; i < visible.length; i++) {
        final iy = listY + i * itemHeight;
        canvas.drawText(
          visible[i],
          Offset((x + 6).toDouble(), (iy + 3).toDouble()),
          color: i == selectedIndex ? const Color(255, 255, 255) : textColor,
          size: 16,
        );
      }
    }
  }

  int itemAt(int px, int py) {
    if (!opened) return -1;
    final listY = y + height;
    final visible = items.length < maxVisibleItems ? items.length : maxVisibleItems;
    final listH = visible * itemHeight;
    if (px < x || px >= x + width || py < listY || py >= listY + listH) return -1;
    return (py - listY) ~/ itemHeight;
  }

  void select(int index) {
    if (index >= 0 && index < items.length) {
      selectedIndex = index;
      opened = false;
      onChanged?.call();
    }
  }
}
