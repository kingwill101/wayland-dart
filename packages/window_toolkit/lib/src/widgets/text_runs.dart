import '../drawing/color.dart';
import '../font/font.dart';
import '../font/font_database.dart';
import '../font/painter_font.dart';
import '../font/text_layout.dart';
import '../painter/painter.dart';
import '../style/style_patch.dart';
import '../style.dart';
import '../widget.dart';

/// A single-line text widget that uses the toolkit's shared shaped text path.
///
/// The optional icon run remains available for callers that explicitly need
/// separate sizing, but normal text uses the resolved style font for the
/// complete string. This matches Waybar/Pango: the configured font stack is
/// allowed to shape and fall back across icon and UI glyphs together.
class TextRuns extends Widget {
  String text;
  Font textFont;
  Font iconFont;
  Color? color;
  double runSpacing;
  bool splitPrivateUse;

  String? _geometryKey;
  Font? _resolvedTextFont;
  Font? _resolvedIconFont;
  double _resolvedSpacing = 0;
  Rect _resolvedBounds = const Rect.fromLTWH(0, 0, 0, 0);

  TextRuns(
    this.text, {
    this.textFont = const Font.ui(),
    this.iconFont = const Font.icon(),
    this.color,
    this.runSpacing = 3,
    this.splitPrivateUse = false,
    super.key,
  }) {
    width = 1;
    height = 16;
  }

  @override
  StylePatch localOverrides() => StylePatch(color: color);

  Color get resolvedColor {
    final style = resolvedStyle();
    return styledColor(style.color, style);
  }

  @override
  void measure(Painter painter) {
    _prepareGeometry(painter);
    final spacing = _resolvedSpacing;
    final ui = _resolvedTextFont!;
    final icons = _resolvedIconFont!;
    final measured = splitPrivateUse
        ? painter.measureTextRuns(
            text,
            textFont: ui,
            iconFont: icons,
            runSpacing: spacing,
            splitPrivateUse: true,
          )
        : painter.measureTextFont(text, ui);
    width = measured.ceil().clamp(1, 100000);
    final lineHeight = TextLayout.lineHeightOf(painter.fontMetrics(ui));
    height =
        (lineHeight > _resolvedBounds.height
                ? lineHeight
                : _resolvedBounds.height)
            .ceil()
            .clamp(ui.pixelSize.ceil(), 1000);
  }

  @override
  void draw(Painter canvas) {
    _prepareGeometry(canvas);
    final spacing = _resolvedSpacing;
    final ui = _resolvedTextFont!;
    final icons = _resolvedIconFont!;
    final bounds = _resolvedBounds;
    final originY = TextLayout.drawOriginForBounds(
      y.toDouble(),
      height.toDouble(),
      bounds,
    );
    if (splitPrivateUse) {
      _drawCenteredRuns(canvas, ui, icons, resolvedColor, spacing);
    } else {
      canvas.drawTextFont(
        text,
        Offset(x.toDouble(), originY),
        font: ui,
        color: resolvedColor,
      );
    }
  }

  void _prepareGeometry(Painter painter) {
    final style = resolvedStyle();
    final css = widgetStyle;
    final ui = FontDatabase.instance.resolveRequest(
      _styledFont(textFont, style: style, css: css),
    );
    final icons = FontDatabase.instance.resolveRequest(
      _styledFont(iconFont, style: style, css: css),
    );
    final spacing =
        (style.letterSpacing == 0 ? runSpacing : style.letterSpacing)
            .clamp(0.0, 100.0)
            .toDouble();
    final key = '$text|$ui|$icons|$spacing|$splitPrivateUse';
    if (_geometryKey == key && _resolvedTextFont != null) return;

    _geometryKey = key;
    _resolvedTextFont = ui;
    _resolvedIconFont = icons;
    _resolvedSpacing = spacing;
    _resolvedBounds = painter.measureTextRunsBounds(
      text,
      textFont: ui,
      iconFont: icons,
      runSpacing: spacing,
      splitPrivateUse: splitPrivateUse,
    );
  }

  void _drawCenteredRuns(
    Painter canvas,
    Font ui,
    Font icons,
    Color color,
    double spacing,
  ) {
    final runs = FontTextRun.split(text, textFont: ui, iconFont: icons);
    final centerY = y + height / 2.0;
    var advance = 0.0;
    for (var i = 0; i < runs.length; i++) {
      final run = runs[i];
      final resolved = FontDatabase.instance.resolveRequest(run.font);
      final bounds = canvas.measureTextBounds(
        run.text,
        size: resolved.pixelSize,
        fontFamily: resolved.family,
      );
      final runOriginY = centerY - (bounds.top + bounds.bottom) / 2.0;
      if (i > 0 &&
          FontTextRun.isPrivateUse(runs[i - 1].text) !=
              FontTextRun.isPrivateUse(run.text)) {
        advance += spacing;
      }
      canvas.drawTextFont(
        run.text,
        Offset(x.toDouble() + advance, runOriginY),
        font: run.font,
        color: color,
      );
      // Use the exact bounds probe used for vertical centering. Some icon
      // glyphs visibly extend beyond their nominal advance; reserving the
      // right-side ink here prevents it from covering the following `1` in
      // values such as `100%`.
      final typographicAdvance = canvas.measureTextFont(run.text, run.font);
      advance += typographicAdvance > bounds.right
          ? typographicAdvance
          : bounds.right;
    }
  }

  Font _styledFont(Font base, {required Style style, required StylePatch css}) {
    // Skia's low-level shaper does not guarantee Pango-style fallback for a
    // private-use glyph inside a UI run. Keep the configured icon role for
    // Nerd/FontAwesome runs even when CSS supplies a UI family stack.
    final isIconRole = base.role == FontRole.icon;
    final requestedFamily =
        css.fontFamily ??
        (base.family.isNotEmpty ? base.family : style.fontFamily);
    final family = isIconRole ? null : requestedFamily;
    return Font(
      family: family ?? '',
      pixelSize: css.fontSize ?? style.fontSize,
      weight: css.fontWeight ?? base.weight,
      italic: css.fontStyle == TextStyle.normal
          ? false
          : css.fontStyle == TextStyle.italic ||
                css.fontStyle == TextStyle.oblique
          ? true
          : base.italic,
      styleHint: base.styleHint,
      role: family == null ? base.role : null,
    );
  }
}
