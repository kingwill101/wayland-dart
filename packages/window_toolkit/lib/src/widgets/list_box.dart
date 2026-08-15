import '../drawing/color.dart';
import '../font/font.dart';
import '../interaction.dart';
import '../painter/painter.dart';
import '../style.dart';
import '../style/style_patch.dart';
import '../widget.dart';

class ListBox extends Widget {
  List<String> items;
  int selectedIndex;
  Color textColor;
  Color backgroundColor;
  Color selectedColor;
  Color hoverColor;
  Color borderColor;
  int itemHeight;
  bool multiSelect;
  VoidCallback? onChanged;

  int _hoverIndex = -1;

  int get hoveredIndex => _hoverIndex;
  int _scrollOffset = 0;

  ListBox({
    this.items = const [],
    this.selectedIndex = -1,
    this.textColor = const Color(255, 255, 255),
    this.backgroundColor = const Color(30, 30, 30),
    this.selectedColor = const Color(60, 100, 200),
    this.hoverColor = const Color(45, 45, 45),
    this.borderColor = const Color(70, 70, 70),
    this.itemHeight = 22,
    this.multiSelect = false,
    this.onChanged,
  }) : assert(itemHeight > 0, 'ListBox itemHeight must be > 0') {
    onMouseLeave = () {
      if (_hoverIndex != -1) {
        setState(() => _hoverIndex = -1);
        setInteractionState(WidgetState.hovered, false);
      }
    };
  }

  @override
  bool get acceptsFocus => true;

  @override
  Style styleRole() => Style(
    color: textColor,
    backgroundColor: backgroundColor,
    borderColor: borderColor,
  );

  @override
  void onMouseMove(int x, int y) {
    final next = itemAt(x, y);
    if (next == _hoverIndex) return;
    setState(() {
      _hoverIndex = next;
      setInteractionState(WidgetState.hovered, next >= 0);
    });
  }

  int get _maxScroll =>
      (items.length * itemHeight - height).clamp(0, items.length * itemHeight);

  @override
  void draw(Painter canvas) {
    final base = resolvedStyle();
    final selected = resolvedStyleOn(const [
      'selected',
    ], local: StylePatch(backgroundColor: selectedColor));
    final hovered = resolvedStyleOn(const [
      'hover',
    ], local: StylePatch(backgroundColor: hoverColor));
    drawStyledBox(canvas, style: base);

    canvas.save();
    canvas.clipRect(
      Rect.fromLTWH(
        x.toDouble(),
        y.toDouble(),
        width.toDouble(),
        height.toDouble(),
      ),
    );

    for (var i = 0; i < items.length; i++) {
      final iy = y + i * itemHeight - _scrollOffset;
      if (iy + itemHeight < y || iy > y + height) continue;

      final isSelected = i == selectedIndex;
      final isHovered = i == _hoverIndex;

      if (isSelected) {
        canvas.drawRect(
          Rect.fromLTWH(
            x.toDouble(),
            iy.toDouble(),
            width.toDouble(),
            itemHeight.toDouble(),
          ),
          Paint()..color = styledColor(selected.backgroundColor!, selected),
        );
      } else if (isHovered) {
        canvas.drawRect(
          Rect.fromLTWH(
            x.toDouble(),
            iy.toDouble(),
            width.toDouble(),
            itemHeight.toDouble(),
          ),
          Paint()..color = styledColor(hovered.backgroundColor!, hovered),
        );
      }

      drawStyledText(
        canvas,
        items[i],
        Offset(
          (x + styledPaddingLeft(4)).toDouble(),
          (iy + styledPaddingTop(3)).toDouble(),
        ),
        style: base,
        color: base.color,
        fallback: const Font(pixelSize: 16),
      );
    }

    canvas.restore();

    // Scrollbar
    final totalH = items.length * itemHeight;
    if (totalH > height && height > 0) {
      final barH = (height * height ~/ totalH).clamp(8, height);
      final barY = (_scrollOffset * (height - barH) ~/ _maxScroll).clamp(
        0,
        height - barH,
      );
      canvas.drawRect(
        Rect.fromLTWH(
          (x + width - 4).toDouble(),
          (y + barY).toDouble(),
          4,
          barH.toDouble(),
        ),
        Paint()..color = styledColor(base.borderColor, base),
      );
    }
  }

  void scrollBy(int delta) {
    _scrollOffset = (_scrollOffset + delta).clamp(0, _maxScroll);
  }

  int itemAt(int px, int py) {
    if (px < x || px >= x + width || py < y || py >= y + height) return -1;
    final index = (py - y + _scrollOffset) ~/ itemHeight;
    if (index < 0 || index >= items.length) return -1;
    return index;
  }

  void select(int index) {
    if (index >= 0 && index < items.length) {
      selectedIndex = index;
      scrollIntoView(index);
      onChanged?.call();
    }
  }

  void scrollIntoView(int index) {
    final itemTop = index * itemHeight;
    if (itemTop < _scrollOffset) {
      _scrollOffset = itemTop;
    } else if (itemTop + itemHeight > _scrollOffset + height) {
      _scrollOffset = itemTop + itemHeight - height;
    }
  }

  @override
  void onKeyPressed(KeyEvent event) {
    if (!event.isPressed) return;
    final k = event.key;
    if (k == 103) {
      // up
      if (selectedIndex > 0) select(selectedIndex - 1);
    } else if (k == 108) {
      // down
      if (selectedIndex < items.length - 1) select(selectedIndex + 1);
    } else if (k == 28) {
      // enter
      onChanged?.call();
    }
  }
}
