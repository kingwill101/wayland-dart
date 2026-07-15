import '../drawing/color.dart';
import '../painter/painter.dart';
import 'font.dart';
import 'font_database.dart';
import 'font_metrics.dart';
import 'text_align.dart';
import 'text_layout.dart';
import 'text_option.dart';

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
