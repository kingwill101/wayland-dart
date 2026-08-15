import '../drawing/color.dart';
import '../font/font.dart';
import '../interaction.dart';
import '../mixins/hoverable.dart';
import '../mixins/hover_animated.dart';
import '../painter/painter.dart';
import '../style.dart';
import '../style/style_patch.dart';

import '../widget.dart';

class Dropdown extends Widget with Hoverable, HoverAnimated {
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
    WidgetKey? key,
  }) : assert(itemHeight > 0, 'Dropdown itemHeight must be > 0'),
       assert(maxVisibleItems > 0, 'Dropdown maxVisibleItems must be > 0') {
    width = 160;
    height = itemHeight;
    setInteractionState(WidgetState.expanded, opened);
    onClick = () {
      setState(() {
        opened = !opened;
        setInteractionState(WidgetState.expanded, opened);
      });
      return true;
    };
    tabIndex = 1;
  }

  String? get selectedLabel =>
      selectedIndex >= 0 && selectedIndex < items.length
      ? items[selectedIndex]
      : null;

  @override
  bool get acceptsFocus => true;

  @override
  Style styleRole() => Style(
    color: textColor,
    backgroundColor: backgroundColor,
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

    // Arrow
    final arrowX = x + width - 14;
    final arrowY = y + height ~/ 2;
    final arrowPaint = Paint()..color = styledColor(base.color, base);
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
      drawStyledText(
        canvas,
        selectedLabel!,
        Offset(
          (x + styledPaddingLeft(6)).toDouble(),
          (y + styledPaddingTop(3)).toDouble(),
        ),
        style: base,
        color: base.color,
        fallback: const Font(pixelSize: 16),
      );
    }

    // Dropdown list
    if (opened && items.isNotEmpty) {
      final listH =
          (items.length < maxVisibleItems ? items.length : maxVisibleItems) *
          itemHeight;
      final listY = y + height;

      canvas.drawRRect(
        Rect.fromLTWH(
          x.toDouble(),
          listY.toDouble(),
          width.toDouble(),
          listH.toDouble(),
        ),
        base.borderRadius,
        base.borderRadius,
        Paint()..color = styledColor(base.backgroundColor!, base),
      );

      final visible = items.length < maxVisibleItems
          ? items
          : items.sublist(0, maxVisibleItems);
      for (var i = 0; i < visible.length; i++) {
        final iy = listY + i * itemHeight;
        drawStyledText(
          canvas,
          visible[i],
          Offset(
            (x + styledPaddingLeft(6)).toDouble(),
            (iy + styledPaddingTop(3)).toDouble(),
          ),
          style: base,
          color: i == selectedIndex ? base.color : base.color,
          fallback: const Font(pixelSize: 16),
        );
      }
    }
  }

  int itemAt(int px, int py) {
    if (!opened) return -1;
    final listY = y + height;
    final visible = items.length < maxVisibleItems
        ? items.length
        : maxVisibleItems;
    final listH = visible * itemHeight;
    if (px < x || px >= x + width || py < listY || py >= listY + listH)
      return -1;
    return (py - listY) ~/ itemHeight;
  }

  void select(int index) {
    if (index >= 0 && index < items.length) {
      setState(() {
        selectedIndex = index;
        opened = false;
        setInteractionState(WidgetState.selected, true);
        setInteractionState(WidgetState.expanded, false);
      });
      onChanged?.call();
    }
  }
}
