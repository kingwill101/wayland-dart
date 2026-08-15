import '../drawing/color.dart';
import '../font/font.dart';
import '../mixins/hoverable.dart';
import '../mixins/hover_animated.dart';
import '../painter/painter.dart';
import '../style.dart';
import '../style/style_patch.dart';
import '../widget.dart';

class MenuItem extends Widget with Hoverable, HoverAnimated {
  String label;
  Color textColor;
  Color backgroundColor;
  Color hoverColor;
  int itemHeight;
  VoidCallback? onTriggered;

  MenuItem(
    this.label, {
    this.textColor = const Color(255, 255, 255),
    this.backgroundColor = const Color(36, 36, 36),
    this.hoverColor = const Color(55, 55, 55),
    this.itemHeight = 24,
    this.onTriggered,
  }) : assert(itemHeight > 0, 'MenuItem itemHeight must be > 0') {
    width = label.length * 8 + 24;
    height = itemHeight;
    onClick = () {
      onTriggered?.call();
      return true;
    };
  }

  @override
  bool get acceptsFocus => true;

  @override
  Style styleRole() => Style(
    color: textColor,
    backgroundColor: backgroundColor,
    borderColor: palette.mid,
    borderWidth: 0,
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
        (x + styledPaddingLeft(12)).toDouble(),
        (y + (itemHeight - 16) ~/ 2 + styledPaddingTop()).toDouble(),
      ),
      style: base,
      color: base.color,
      fallback: const Font(pixelSize: 16),
    );
  }
}

class Menu extends Widget {
  List<MenuItem> items;
  Color borderColor;
  int padding;

  Menu({
    required this.items,
    this.borderColor = const Color(70, 70, 70),
    this.padding = 4,
  }) {
    var maxW = 0;
    var totalH = padding * 2;
    for (final item in items) {
      if (item.width > maxW) maxW = item.width;
      totalH += item.height;
    }
    width = maxW + padding * 2;
    height = totalH;
  }

  @override
  Style styleRole() => Style(
    color: palette.text,
    backgroundColor: palette.base,
    borderColor: borderColor,
  );

  @override
  void draw(Painter canvas) {
    final style = resolvedStyle();
    drawStyledBox(canvas, style: style);

    var cy = y + styledPaddingTop(padding);
    for (final item in items) {
      item.x = x + styledPaddingLeft(padding);
      item.y = cy;
      item.width =
          width - styledPaddingLeft(padding) - styledPaddingRight(padding);
      item.draw(canvas);
      cy += item.height;
    }
  }

  @override
  bool hitTest(int px, int py) {
    if (!super.hitTest(px, py)) return false;
    for (final item in items.reversed) {
      if (item.hitTest(px, py)) return true;
    }
    return false;
  }

  int itemAt(int px, int py) {
    for (var i = 0; i < items.length; i++) {
      if (items[i].hitTest(px, py)) return i;
    }
    return -1;
  }
}
