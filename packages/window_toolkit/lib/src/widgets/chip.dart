import '../drawing/color.dart';
import '../font/font.dart';
import '../font/painter_font.dart';
import '../metrics.dart';
import '../painter/painter.dart';
import '../widget.dart';
import 'label.dart';

/// Compact pill/chip control (useful for workspace buttons, tags, status).
class Chip extends Widget {
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
  })  : assert(paddingH == null || paddingH >= 0, 'Chip paddingH must be >= 0'),
        assert(paddingV == null || paddingV >= 0, 'Chip paddingV must be >= 0'),
        borderRadius = borderRadius ?? ThemeMetrics.current.borderRadiusMd,
        paddingH = paddingH ?? ThemeMetrics.current.paddingMd,
        paddingV = paddingV ?? ThemeMetrics.current.paddingSm,
        fontSize = fontSize ?? ThemeMetrics.current.fontSize {
    onMouseEnter = () => hovered = true;
    onMouseLeave = () => hovered = false;
  }

  Color get _bg {
    if (backgroundColor != null) return backgroundColor!;
    if (selected) return palette.highlight;
    if (hovered) return palette.midlight;
    return palette.button;
  }

  Color get _fg {
    if (textColor != null) return textColor!;
    if (selected) return palette.highlightedText;
    return palette.buttonText;
  }

  @override
  void measure(Painter painter) {
    final font = Font.ui(pixelSize: fontSize);
    final adv = painter.measureTextFont(label, font);
    final metrics = painter.fontMetrics(font);
    width = adv.ceil() + paddingH * 2;
    height = metrics.height.ceil().clamp(fontSize.ceil(), 100) + paddingV * 2;
    if (height < fontSize.ceil() + paddingV * 2) {
      height = fontSize.ceil() + paddingV * 2;
    }
  }

  @override
  void draw(Painter canvas) {
    final rect = Rect.fromLTWH(
      x.toDouble(),
      y.toDouble(),
      width.toDouble(),
      height.toDouble(),
    );
    canvas.drawRRect(rect, borderRadius, borderRadius, Paint()..color = _bg);
    if (borderColor != null) {
      canvas.drawRRect(
        Rect.fromLTWH(x + 0.5, y + 0.5, width - 1.0, height - 1.0),
        borderRadius,
        borderRadius,
        Paint()
          ..color = borderColor!
          ..style = PaintStyle.stroke
          ..strokeWidth = 1,
      );
    }

    final text = Label(
      label,
      color: _fg,
      fontSize: fontSize,
    );
    text.measure(canvas);
    text.x = x + (width - text.width) ~/ 2;
    text.y = y + (height - text.height) ~/ 2;
    text.width = text.width;
    text.height = text.height;
    text.draw(canvas);
  }
}
