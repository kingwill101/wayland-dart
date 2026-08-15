import '../drawing/color.dart';
import '../font/font.dart';
import '../painter/painter.dart';
import '../style.dart';
import '../style/style_patch.dart';
import '../mixins/hoverable.dart';
import '../widget.dart';

class Tooltip extends Widget with Hoverable {
  @override
  @override
  List<Widget> get children => [child];

  String text;
  Widget child;
  int showDelayMs;
  final Color? _backgroundColor;
  final Color? _textColor;
  final Color? _borderColor;
  int padding;
  double fontSize;
  bool drawBorder;
  bool visible;

  Color get backgroundColor => _backgroundColor ?? palette.tooltipBase;
  Color get textColor => _textColor ?? palette.tooltipText;
  Color get borderColor => _borderColor ?? palette.mid;

  Tooltip({
    required this.text,
    required this.child,
    this.showDelayMs = 500,
    Color? backgroundColor,
    Color? textColor,
    Color? borderColor,
    this.padding = 6,
    this.fontSize = 12,
    this.drawBorder = true,
    this.visible = false,
  }) : _backgroundColor = backgroundColor,
       _textColor = textColor,
       _borderColor = borderColor {
    width = child.width;
    height = child.height;
    onMouseEnter = () {
      setHovering(true);
      setState(() => visible = true);
    };
    onMouseLeave = () {
      setHovering(false);
      setState(() => visible = false);
    };
    onClick = () {
      visible = !visible;
      return true;
    };
  }

  @override
  Style styleRole() => Style(
    color: textColor,
    backgroundColor: backgroundColor,
    borderColor: borderColor,
  );

  @override
  void draw(Painter canvas) {
    final style = resolvedStyle();
    child
      ..x = x
      ..y = y
      ..width = width
      ..height = height;
    child.draw(canvas);

    if (visible && text.isNotEmpty) {
      final bounds = measureStyledTextBounds(
        canvas,
        text,
        style: style,
        fallback: Font(pixelSize: fontSize),
      );
      final padL = styledPaddingLeft(padding);
      final padR = styledPaddingRight(padding);
      final padT = styledPaddingTop(padding);
      final padB = styledPaddingBottom(padding);
      final tipW = bounds.width + padL + padR;
      final tipH = bounds.height + padT + padB;
      final tipX = x + (width - tipW) / 2;
      final tipY = y - tipH; // was -4 gap; should sit on bar (gap 0)

      drawStyledRect(
        canvas,
        Rect.fromLTWH(tipX, tipY, tipW, tipH),
        style: style.overlay(
          StylePatch(
            borderTopWidth: drawBorder ? 1 : 0,
            borderRightWidth: drawBorder ? 1 : 0,
            borderBottomWidth: drawBorder ? 1 : 0,
            borderLeftWidth: drawBorder ? 1 : 0,
          ),
        ),
      );

      // Center glyph bounds inside the tip box (baseline-aware for Skia).
      final originX = tipX + padL - bounds.left;
      final originY = tipY + padT - bounds.top;

      drawStyledText(
        canvas,
        text,
        Offset(originX, originY),
        style: style,
        color: style.color,
        fallback: Font(pixelSize: fontSize),
      );
    }
  }

  @override
  bool hitTest(int px, int py) {
    return px >= x && px < x + width && py >= y && py < y + height;
  }
}
