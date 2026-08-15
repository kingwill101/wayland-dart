import '../drawing/color.dart';
import '../font/font.dart';
import '../font/painter_font.dart';
import '../interaction.dart';
import '../metrics.dart';
import '../mixins/hoverable.dart';
import '../mixins/hover_animated.dart';
import '../painter/painter.dart';
import '../style.dart';
import '../widget.dart';
import 'label.dart';

/// Compact pill/chip control (useful for workspace buttons, tags, status).
class Chip extends Widget with Hoverable, HoverAnimated {
  String label;
  Color? backgroundColor;
  Color? textColor;
  Color? borderColor;
  double borderRadius;
  int paddingH;
  int paddingV;
  bool selected;
  bool hovered;
  double fontSize;

  Chip({
    required this.label,
    this.backgroundColor,
    this.textColor,
    this.borderColor,
    double? borderRadius,
    int? paddingH,
    int? paddingV,
    this.selected = false,
    this.hovered = false,
    double? fontSize,
  }) : assert(paddingH == null || paddingH >= 0, 'Chip paddingH must be >= 0'),
       assert(paddingV == null || paddingV >= 0, 'Chip paddingV must be >= 0'),
       borderRadius = borderRadius ?? ThemeMetrics.current.borderRadiusMd,
       paddingH = paddingH ?? ThemeMetrics.current.paddingMd,
       paddingV = paddingV ?? ThemeMetrics.current.paddingSm,
       fontSize = fontSize ?? ThemeMetrics.current.fontSize {
    setInteractionState(WidgetState.hovered, hovered);
  }

  Color get _bg {
    if (backgroundColor != null) return backgroundColor!;
    if (selected) return palette.highlight;
    return transitionHover(palette.button, palette.midlight);
  }

  Color get _fg {
    if (textColor != null) return textColor!;
    if (selected) return palette.highlightedText;
    return palette.buttonText;
  }

  @override
  void measure(Painter painter) {
    final style = resolvedStyle();
    final font = Font.ui(pixelSize: style.fontSize);
    final adv = painter.measureTextFont(label, font);
    final metrics = painter.fontMetrics(font);
    final padH = styledPaddingLeft(paddingH) + styledPaddingRight(paddingH);
    final padV = styledPaddingTop(paddingV) + styledPaddingBottom(paddingV);
    width = adv.ceil() + padH;
    height = metrics.height.ceil().clamp(style.fontSize.ceil(), 100) + padV;
    if (height < style.fontSize.ceil() + padV) {
      height = style.fontSize.ceil() + padV;
    }
  }

  @override
  Style styleRole() => Style(
    color: _fg,
    backgroundColor: _bg,
    borderColor: borderColor ?? palette.mid,
    borderWidth: borderColor == null ? 0 : 1,
    borderRadius: borderRadius,
    fontSize: fontSize,
  );

  @override
  void draw(Painter canvas) {
    final style = resolvedStyle();
    drawStyledBox(canvas, style: style);

    final text = Label(label, color: style.color, fontSize: style.fontSize);
    text.measure(canvas);
    text.x = x + (width - text.width) ~/ 2;
    text.y = y + (height - text.height) ~/ 2;
    text.width = text.width;
    text.height = text.height;
    text.draw(canvas);
  }
}
