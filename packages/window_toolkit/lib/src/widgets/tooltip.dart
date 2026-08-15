import '../drawing/color.dart';
import '../painter/painter.dart';
import '../style.dart';
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
      final bounds = canvas.measureTextBounds(text, size: fontSize);
      final tipW = bounds.width + padding * 2;
      final tipH = bounds.height + padding * 2;
      final tipX = x + (width - tipW) / 2;
      final tipY = y - tipH; // was -4 gap; should sit on bar (gap 0)

      canvas.drawRect(
        Rect.fromLTWH(tipX, tipY, tipW, tipH),
        Paint()..color = style.backgroundColor!,
      );

      if (drawBorder) {
        canvas.drawRect(
          Rect.fromLTWH(tipX + 0.5, tipY + 0.5, tipW - 1, tipH - 1),
          Paint()
            ..color = style.borderColor
            ..style = PaintStyle.stroke
            ..strokeWidth = 1,
        );
      }

      // Center glyph bounds inside the tip box (baseline-aware for Skia).
      final originX = tipX + (tipW - bounds.width) / 2 - bounds.left;
      final originY = tipY + (tipH - bounds.height) / 2 - bounds.top;

      canvas.drawText(
        text,
        Offset(originX, originY),
        color: style.color,
        size: fontSize,
      );
    }
  }

  @override
  bool hitTest(int px, int py) {
    return px >= x && px < x + width && py >= y && py < y + height;
  }
}
