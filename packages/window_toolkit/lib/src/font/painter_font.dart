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
/// Keeping icon and UI glyphs in separate runs prevents a renderer's fallback
/// shaper from replacing a private-use icon when the same string also contains
/// numbers or labels.
class FontTextRun {
  final String text;
  final Font font;

  const FontTextRun(this.text, this.font);

  /// Splits private-use glyphs from normal text using the supplied roles.
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

  /// Measures text using separate UI and private-use icon runs.
  double measureTextRuns(
    String text, {
    required Font textFont,
    required Font iconFont,
    double runSpacing = 3,
  }) {
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
      width += measureTextFont(run.text, run.font);
    }
    return width;
  }

  /// Draws text using separate UI and private-use icon runs.
  double drawTextRuns(
    String text,
    Offset position, {
    required Font textFont,
    required Font iconFont,
    Color? color,
    double runSpacing = 3,
  }) {
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
      advance += measureTextFont(run.text, run.font);
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
