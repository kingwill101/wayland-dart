import '../drawing/color.dart';
import '../painter/painter.dart';
import 'font.dart';
import 'font_database.dart';
import 'font_metrics.dart';
import 'text_align.dart';
import 'text_layout.dart';
import 'text_option.dart';

/// One independently shaped text run.
///
/// Explicit runs are retained for controls that intentionally use different
/// sizes for icons and labels. Normal toolkit text should use one [Font] and
/// let the backend's fallback shaper choose faces per glyph.
class FontTextRun {
  final String text;
  final Font font;

  const FontTextRun(this.text, this.font);

  /// Splits private-use glyphs from normal text using the supplied fonts.
  ///
  /// This is opt-in behavior. It is not used by [TextRuns] by default because
  /// Waybar/Pango shapes the complete label against its configured family
  /// stack, including fallback for private-use and emoji glyphs.
  static List<FontTextRun> split(
    String text, {
    required Font textFont,
    required Font iconFont,
  }) {
    if (text.isEmpty) return const [];

    final runs = <FontTextRun>[];
    final buffer = StringBuffer();
    bool? iconRun;

    void flush() {
      if (buffer.isEmpty || iconRun == null) return;
      final useIconFont = iconRun;
      runs.add(
        FontTextRun(buffer.toString(), useIconFont ? iconFont : textFont),
      );
      buffer.clear();
    }

    for (final rune in text.runes) {
      final char = String.fromCharCode(rune);
      final isIcon = isPrivateUse(char);
      if (iconRun != null && iconRun != isIcon) flush();
      iconRun = isIcon;
      buffer.write(char);
    }
    flush();
    return runs;
  }

  static bool isPrivateUse(String text) {
    for (final rune in text.runes) {
      if ((rune >= 0xE000 && rune <= 0xF8FF) ||
          (rune >= 0xF0000 && rune <= 0xFFFFD) ||
          (rune >= 0x100000 && rune <= 0x10FFFD)) {
        return true;
      }
    }
    return false;
  }
}

/// [Painter] helpers for Qt-style font metrics and rect-aligned drawing.
extension PainterFont on Painter {
  /// Resolve [font] (roles → family) then draw at baseline [position].
  void drawTextFont(
    String text,
    Offset position, {
    required Font font,
    Color? color,
  }) {
    final resolved = FontDatabase.instance.resolveRequest(font);
    drawText(
      text,
      position,
      color: color,
      size: resolved.pixelSize,
      fontFamily: resolved.family,
    );
  }

  /// Layout width via [FontMetrics.horizontalAdvance].
  double measureTextFont(String text, Font font) {
    return FontDatabase.instance.metrics(font).horizontalAdvance(text);
  }

  /// Measures the horizontal space a run actually occupies when painted.
  ///
  /// Some icon fonts have ink that extends past their typographic advance.
  /// Using only [measureTextFont] can therefore place the following text on
  /// top of the icon (most visibly the `1` in `100%`).  Keep layout based on
  /// the advance, but reserve any positive right-side ink overhang as well.
  double measureTextRunAdvance(String text, Font font) {
    final resolved = FontDatabase.instance.resolveRequest(font);
    final advance = measureTextFont(text, font);
    final bounds = measureTextBounds(
      text,
      size: resolved.pixelSize,
      fontFamily: resolved.family,
    );
    return advance > bounds.right ? advance : bounds.right;
  }

  /// Measures text through the shared shaped path.
  ///
  /// [splitPrivateUse] is opt-in for controls that intentionally use a
  /// separate icon font. The default keeps the family stack intact so font
  /// fallback can select a face per glyph.
  double measureTextRuns(
    String text, {
    required Font textFont,
    required Font iconFont,
    double runSpacing = 3,
    bool splitPrivateUse = false,
  }) {
    if (!splitPrivateUse) return measureTextFont(text, textFont);
    final runs = FontTextRun.split(
      text,
      textFont: textFont,
      iconFont: iconFont,
    );
    var width = 0.0;
    for (var i = 0; i < runs.length; i++) {
      final run = runs[i];
      if (i > 0 && _needsRunSpacing(runs[i - 1], run)) {
        width += runSpacing;
      }
      width += measureTextRunAdvance(run.text, run.font);
    }
    return width;
  }

  /// Measures the vertical ink bounds of a mixed-font line.
  ///
  /// A UI label and a private-use icon often have different ascent/descent
  /// metrics. Returning the union keeps callers from centering the icon using
  /// only the UI font's line box, which makes status-bar icons visibly drift
  /// above or below their neighbouring text.
  Rect measureTextRunsBounds(
    String text, {
    required Font textFont,
    required Font iconFont,
    double runSpacing = 3,
    bool splitPrivateUse = false,
  }) {
    final runs = splitPrivateUse
        ? FontTextRun.split(text, textFont: textFont, iconFont: iconFont)
        : <FontTextRun>[FontTextRun(text, textFont)];
    if (runs.isEmpty) return const Rect.fromLTWH(0, 0, 0, 0);

    var top = double.infinity;
    var bottom = double.negativeInfinity;
    var advance = 0.0;
    for (var i = 0; i < runs.length; i++) {
      final run = runs[i];
      final resolved = FontDatabase.instance.resolveRequest(run.font);
      final bounds = measureTextBounds(
        run.text,
        size: resolved.pixelSize,
        fontFamily: resolved.family,
      );
      if (bounds.top < top) top = bounds.top;
      if (bounds.bottom > bottom) bottom = bounds.bottom;
      if (i > 0 && _needsRunSpacing(runs[i - 1], run)) {
        advance += runSpacing;
      }
      advance += measureTextRunAdvance(run.text, run.font);
    }
    return Rect.fromLTRB(0, top, advance, bottom);
  }

  /// Draws text through the shared shaped path; see [splitPrivateUse].
  double drawTextRuns(
    String text,
    Offset position, {
    required Font textFont,
    required Font iconFont,
    Color? color,
    double runSpacing = 3,
    bool splitPrivateUse = false,
  }) {
    if (!splitPrivateUse) {
      drawTextFont(text, position, font: textFont, color: color);
      return measureTextFont(text, textFont);
    }
    final runs = FontTextRun.split(
      text,
      textFont: textFont,
      iconFont: iconFont,
    );
    var advance = 0.0;
    for (var i = 0; i < runs.length; i++) {
      final run = runs[i];
      if (i > 0 && _needsRunSpacing(runs[i - 1], run)) {
        advance += runSpacing;
      }
      drawTextFont(
        run.text,
        Offset(position.dx + advance, position.dy),
        font: run.font,
        color: color,
      );
      advance += measureTextRunAdvance(run.text, run.font);
    }
    return advance;
  }

  /// Add a small visual separation at every icon/text boundary.
  ///
  /// An explicit space is still included in the run's measured advance, but
  /// it must not be the only separation: icon glyph ink often extends beyond
  /// its nominal advance and can cover a narrow following glyph such as the
  /// `1` in `100%`.
  bool _needsRunSpacing(FontTextRun previous, FontTextRun current) {
    if (FontTextRun.isPrivateUse(previous.text) ==
        FontTextRun.isPrivateUse(current.text)) {
      return false;
    }
    return true;
  }

  /// Full metrics for [font].
  FontMetrics fontMetrics(Font font) => FontDatabase.instance.metrics(font);

  /// Qt `QPainter::drawText(QRect, flags, text)` — single line, aligned in [rect].
  ///
  /// ```dart
  /// painter.drawTextInRect(
  ///   'Apps',
  ///   Rect.fromLTWH(0, 0, 80, 30),
  ///   font: Font.ui(),
  ///   option: TextOption.leftCenter,
  /// );
  /// ```
  TextLineLayout drawTextInRect(
    String text,
    Rect rect, {
    required Font font,
    TextOption option = const TextOption(align: TextAlign.leftCenter),
    Color? color,
  }) {
    return TextLayout.drawInRect(
      this,
      text,
      rect,
      font: font,
      option: option,
      color: color,
    );
  }

  /// Multi-line (`\n`) variant of [drawTextInRect].
  TextBlockLayout drawTextBlockInRect(
    String text,
    Rect rect, {
    required Font font,
    TextOption option = const TextOption(align: TextAlign.center),
    Color? color,
  }) {
    return TextLayout.drawBlockInRect(
      this,
      text,
      rect,
      font: font,
      option: option,
      color: color,
    );
  }

  /// Convenience: vertical-center [text] in a full-width strip of height [height].
  TextLineLayout drawTextCenteredY(
    String text, {
    required double x,
    required double width,
    required double height,
    required Font font,
    double y = 0,
    TextHAlign hAlign = TextHAlign.left,
    Color? color,
    TextElideMode elide = TextElideMode.none,
  }) {
    return drawTextInRect(
      text,
      Rect.fromLTWH(x, y, width, height),
      font: font,
      option: TextOption(
        align: TextAlign(horizontal: hAlign, vertical: TextVAlign.center),
        elideMode: elide,
      ),
      color: color,
    );
  }
}
