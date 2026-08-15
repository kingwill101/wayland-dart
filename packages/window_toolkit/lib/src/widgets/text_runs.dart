import '../drawing/color.dart';
import '../font/font.dart';
import '../font/font_database.dart';
import '../font/painter_font.dart';
import '../font/text_layout.dart';
import '../painter/painter.dart';
import '../style/style_patch.dart';
import '../widget.dart';

/// A single-line text widget that keeps UI and private-use icon glyphs in
/// separate toolkit font runs.
///
/// This is the bar-safe counterpart to [Label]. It is useful for formatted
/// strings such as ` 55%` where one value contains both an icon font glyph
/// and normal UI text. Measurement and drawing intentionally share the same
/// run splitter so a module cannot reserve one width and paint another.
class TextRuns extends Widget {
  String text;
  Font textFont;
  Font iconFont;
  Color? color;
  double runSpacing;

  TextRuns(
    this.text, {
    this.textFont = const Font.ui(),
    this.iconFont = const Font.icon(),
    this.color,
    this.runSpacing = 3,
    super.key,
  }) {
    width = 1;
    height = 16;
  }

  @override
  StylePatch localOverrides() => StylePatch(color: color);

  Color get resolvedColor => resolvedStyle().color;

  @override
  void measure(Painter painter) {
    final ui = FontDatabase.instance.resolveRequest(textFont);
    final icons = FontDatabase.instance.resolveRequest(iconFont);
    width = painter
        .measureTextRuns(
          text,
          textFont: ui,
          iconFont: icons,
          runSpacing: runSpacing,
        )
        .ceil()
        .clamp(1, 100000);
    height = TextLayout.lineHeightOf(
      painter.fontMetrics(ui),
    ).ceil().clamp(ui.pixelSize.ceil(), 1000);
  }

  @override
  void draw(Painter canvas) {
    final ui = FontDatabase.instance.resolveRequest(textFont);
    final icons = FontDatabase.instance.resolveRequest(iconFont);
    final bounds = canvas.measureTextBounds(
      'Hg',
      size: ui.pixelSize,
      fontFamily: ui.family,
    );
    final originY = TextLayout.drawOriginForBounds(
      y.toDouble(),
      height.toDouble(),
      bounds,
    );
    canvas.drawTextRuns(
      text,
      Offset(x.toDouble(), originY),
      textFont: ui,
      iconFont: icons,
      color: resolvedColor,
      runSpacing: runSpacing,
    );
  }
}
