import '../drawing/color.dart';
import '../font/font.dart';
import '../painter/painter.dart';
import '../style.dart';
import '../widget.dart';

class Card extends Widget {
  @override
  String? title;
  @override
  List<Widget> children;
  Color backgroundColor;
  Color borderColor;
  int borderWidth;
  int padding;
  int spacing;
  Color titleColor;

  Card({
    this.title,
    List<Widget>? children,
    this.backgroundColor = const Color(28, 28, 28),
    this.borderColor = const Color(90, 90, 90),
    this.borderWidth = 1,
    this.padding = 12,
    this.spacing = 8,
    this.titleColor = const Color(255, 255, 255),
  }) : children = children ?? [];

  @override
  Style styleRole() => Style(
    color: titleColor,
    backgroundColor: backgroundColor,
    borderColor: borderColor,
    borderWidth: borderWidth.toDouble(),
  );

  @override
  void performLayout(int containerWidth) {
    final padLeft = styledPaddingLeft(padding);
    final padRight = styledPaddingRight(padding);
    final padTop = styledPaddingTop(padding);
    final padBottom = styledPaddingBottom(padding);
    width = containerWidth;
    var totalH = padTop + (title == null ? 0 : 22);
    for (final child in children) {
      child.performLayout((width - padLeft - padRight).clamp(0, width).toInt());
      totalH += child.height + spacing;
    }
    if (children.isNotEmpty) totalH -= spacing;
    height = totalH + padBottom;
  }

  void layoutChildren() {
    final padLeft = styledPaddingLeft(padding);
    final padTop = styledPaddingTop(padding);
    final padRight = styledPaddingRight(padding);
    var cy = y + padTop + (title == null ? 0 : 22);
    for (final child in children) {
      child.x = x + padLeft;
      child.y = cy;
      child.width = (width - padLeft - padRight).clamp(0, width).toInt();
      cy += child.height + spacing;
    }
  }

  @override
  void draw(Painter canvas) {
    layoutChildren();
    final style = resolvedStyle();
    drawStyledBox(canvas, style: style);

    if (title != null) {
      drawStyledText(
        canvas,
        title!,
        Offset(
          (x + styledPaddingLeft(padding)).toDouble(),
          (y + styledPaddingTop(padding)).toDouble(),
        ),
        style: style,
        color: style.color,
        fallback: const Font(pixelSize: 16),
      );
    }

    for (final child in children) {
      child.draw(canvas);
    }
  }

  @override
  bool hitTest(int px, int py) {
    layoutChildren();
    if (!super.hitTest(px, py)) return false;
    for (final child in children) {
      if (child.hitTest(px, py)) return true;
    }
    return false;
  }
}
