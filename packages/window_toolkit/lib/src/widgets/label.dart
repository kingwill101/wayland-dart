import '../drawing/color.dart';
import '../font/font.dart';
import '../font/font_database.dart';
import '../font/painter_font.dart';
import '../font/text_layout.dart';
import '../font/text_option.dart';
import '../metrics.dart';
import '../painter/painter.dart';
import '../widget.dart';

/// Text label with proper measurement and baseline-aware vertical centering.
///
/// Prefer constructing with a [Font] so layout uses [FontDatabase] advances
/// (Qt `QFont` + `QFontMetrics::horizontalAdvance`).
class Label extends Widget {
  String text;
  Color? color;

  /// Preferred: full font description (roles / weight / family).
  Font? font;

  /// Legacy size — used when [font] is null.
  double fontSize;

  /// Legacy family — used when [font] is null.
  String fontFamily;

  int? maxWidth;
  bool ellipsis;
  bool softWrap;

  Label(
    this.text, {
    this.color,
    this.font,
    double? fontSize,
    this.fontFamily = 'sans',
    this.maxWidth,
    this.ellipsis = true,
    this.softWrap = false,
  }) : fontSize = fontSize ?? ThemeMetrics.current.fontSize {
    // Stable intrinsic size before [measure] (keeps layout tests / bars predictable).
    height = 16;
    width = (text.length * 8).clamp(1, 10000);
  }

  Color get resolvedColor => color ?? palette.text;

  Font get resolvedFont {
    if (font != null) {
      return FontDatabase.instance.resolveRequest(font!);
    }
    return Font(family: fontFamily, pixelSize: fontSize);
  }

  @override
  void measure(Painter painter) {
    final f = resolvedFont;
    final display = _displayText(painter, f);
    // Layout width = typographic advance (not loose ink bounds).
    final adv = painter.measureTextFont(display, f);
    final metrics = painter.fontMetrics(f);
    width = adv.ceil().clamp(1, maxWidth ?? 100000);
    height = TextLayout.lineHeightOf(metrics).ceil().clamp(f.pixelSize.ceil(), 1000);
    if (height < f.pixelSize.ceil()) height = f.pixelSize.ceil();
  }

  String _displayText(Painter painter, Font f) {
    if (maxWidth == null || !ellipsis) return text;
    final full = painter.measureTextFont(text, f);
    if (full <= maxWidth!) return text;
    return painter.fontMetrics(f).elidedText(text, maxWidth!.toDouble());
  }

  @override
  void draw(Painter canvas) {
    final f = resolvedFont;
    final display = _displayText(canvas, f);
    // Qt-style: draw in this label's rect, vertically centered.
    canvas.drawTextInRect(
      display,
      Rect.fromLTWH(x.toDouble(), y.toDouble(), width.toDouble(), height.toDouble()),
      font: f,
      option: TextOption.leftCenter,
      color: resolvedColor,
    );
  }
}
