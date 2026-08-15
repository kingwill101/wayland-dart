import '../drawing/color.dart';
import '../font/font.dart';
import '../font/font_database.dart';
import '../font/painter_font.dart';
import '../font/text_layout.dart';
import '../font/text_option.dart';
import '../metrics.dart';
import '../painter/painter.dart';
import '../style/style_patch.dart';
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
    super.key,
  }) : assert(fontSize == null || fontSize > 0, 'Label fontSize must be > 0'),
       assert(maxWidth == null || maxWidth > 0, 'Label maxWidth must be > 0'),
       fontSize = fontSize ?? ThemeMetrics.current.fontSize {
    // Stable intrinsic size before [measure] (keeps layout tests / bars predictable).
    height = 16;
    width = (text.length * 8).clamp(1, 10000);
  }

  /// CSS `color` wins, then the explicit [color], then the palette text color.
  Color get resolvedColor {
    final style = resolvedStyle();
    return styledColor(style.color, style);
  }

  @override
  StylePatch localOverrides() => StylePatch(color: color);

  Font get resolvedFont {
    final base = font ?? Font(family: fontFamily, pixelSize: fontSize);
    final css = widgetStyle;
    final styled = Font(
      family: css.fontFamily ?? base.family,
      pixelSize: css.fontSize ?? base.pixelSize,
      weight: css.fontWeight ?? base.weight,
      italic: css.fontStyle == TextStyle.normal
          ? false
          : css.fontStyle == TextStyle.italic ||
                css.fontStyle == TextStyle.oblique
          ? true
          : base.italic,
      styleHint: base.styleHint,
      // A CSS family is concrete and must not be replaced by the semantic
      // role resolver (e.g. `Font.icon()`); it is the toolkit's font stack.
      role: css.fontFamily == null ? base.role : null,
    );
    return FontDatabase.instance.resolveRequest(styled);
  }

  @override
  void measure(Painter painter) {
    final f = resolvedFont;
    final display = _displayText(painter, f);
    // Layout width = typographic advance (not loose ink bounds).
    final adv = painter.measureTextFont(display, f);
    final metrics = painter.fontMetrics(f);
    width = adv.ceil().clamp(1, maxWidth ?? 100000);
    height = TextLayout.lineHeightOf(
      metrics,
    ).ceil().clamp(f.pixelSize.ceil(), 1000);
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
      Rect.fromLTWH(
        x.toDouble(),
        y.toDouble(),
        width.toDouble(),
        height.toDouble(),
      ),
      font: f,
      option: TextOption.leftCenter,
      color: resolvedColor,
    );
  }
}
