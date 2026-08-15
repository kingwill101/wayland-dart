import '../drawing/color.dart';
import '../font/font.dart';
import '../painter/painter.dart';
import '../style.dart';
import '../widget.dart';

class GroupBox extends Widget {
  @override
  String? title;
  @override
  List<Widget> children;
  Color backgroundColor;
  Color borderColor;
  Color titleColor;
  Color titleBg;
  int borderWidth;
  int padding;
  int spacing;
  int titleHeight;

  GroupBox({
    this.title,
    this.children = const <Widget>[],
    this.backgroundColor = const Color(28, 28, 28),
    this.borderColor = const Color(80, 80, 80),
    this.titleColor = const Color(200, 200, 200),
    this.titleBg = const Color(28, 28, 28),
    this.borderWidth = 1,
    this.padding = 12,
    this.spacing = 8,
    this.titleHeight = 22,
  }) : assert(borderWidth >= 0, 'GroupBox borderWidth must be >= 0'),
       assert(padding >= 0, 'GroupBox padding must be >= 0'),
       assert(spacing >= 0, 'GroupBox spacing must be >= 0');

  int get _titleOffset => title == null ? 0 : titleHeight;

  @override
  Style styleRole() => Style(
    color: titleColor,
    backgroundColor: backgroundColor,
    borderColor: borderColor,
    borderWidth: borderWidth.toDouble(),
  );

  @override
  void performLayout(int containerWidth) {
    width = containerWidth;
    final padL = styledPaddingLeft(padding);
    final padR = styledPaddingRight(padding);
    final padT = styledPaddingTop(padding);
    final padB = styledPaddingBottom(padding);
    var cy = padT + _titleOffset;
    for (final child in children) {
      child.performLayout((width - padL - padR).clamp(0, width).toInt());
      cy += child.height + spacing;
    }
    if (children.isNotEmpty) cy -= spacing;
    height = cy + padB;
  }

  @override
  void draw(Painter canvas) {
    performLayout(width);
    final style = resolvedStyle();
    drawStyledBox(canvas, style: style);

    // Title
    if (title != null) {
      final titleW = title!.length * 8 + 8;
      final titleX = x + styledPaddingLeft(padding);
      canvas.drawRect(
        Rect.fromLTWH(
          titleX.toDouble(),
          y.toDouble(),
          titleW.toDouble(),
          titleHeight.toDouble(),
        ),
        Paint()..color = styledColor(style.backgroundColor ?? titleBg, style),
      );
      drawStyledText(
        canvas,
        title!,
        Offset(
          (titleX + 4).toDouble(),
          (y + (titleHeight - 16) ~/ 2).toDouble(),
        ),
        style: style,
        color: style.color,
        fallback: const Font(pixelSize: 16),
      );
    }

    // Children
    var cy = y + styledPaddingTop(padding) + _titleOffset;
    for (final child in children) {
      child.x = x + styledPaddingLeft(padding);
      child.y = cy;
      child.width =
          (width - styledPaddingLeft(padding) - styledPaddingRight(padding))
              .clamp(0, width)
              .toInt();
      child.draw(canvas);
      cy += child.height + spacing;
    }
  }

  @override
  bool hitTest(int px, int py) {
    if (!super.hitTest(px, py)) return false;
    for (final child in children) {
      if (child.hitTest(px, py)) return true;
    }
    return false;
  }
}
