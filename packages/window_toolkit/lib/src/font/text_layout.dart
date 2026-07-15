import '../drawing/color.dart';
import '../painter/painter.dart';
import 'font.dart';
import 'font_database.dart';
import 'font_metrics.dart';
import 'painter_font.dart';
import 'text_align.dart';
import 'text_option.dart';

/// Result of laying out a single line inside a rectangle.
///
/// [baseline] is the point to pass to [Painter.drawText] / [PainterFont.drawTextFont]
/// (Skia baseline origin). [displayText] may be elided.
class TextLineLayout {
  /// Text actually drawn (after elide).
  final String displayText;

  /// Baseline origin for [Painter.drawText].
  final Offset baseline;

  /// Typographic advance of [displayText].
  final double advance;

  /// Line box height used for vertical placement (ascent+descent+leading).
  final double lineHeight;

  /// Target rectangle the line was placed into.
  final Rect rect;

  const TextLineLayout({
    required this.displayText,
    required this.baseline,
    required this.advance,
    required this.lineHeight,
    required this.rect,
  });
}

/// Multi-line layout result.
class TextBlockLayout {
  final List<TextLineLayout> lines;
  final Rect rect;
  final double contentWidth;
  final double contentHeight;

  const TextBlockLayout({
    required this.lines,
    required this.rect,
    required this.contentWidth,
    required this.contentHeight,
  });
}

/// Qt-inspired text positioning (QPainter::drawText + QFontMetrics + alignment).
///
/// ## Draw origin (Skia shaped blobs)
///
/// With `harfbuzzShapeDontWrapOrReorder`, [Painter.drawText] places the **text
/// blob origin** at `(x, y)`. That origin is the **line-box top**
/// (`blob.bounds.top ≈ 0`, `bottom ≈ lineH`) — **not** the alphabetic baseline.
///
/// [Painter.measureTextBounds] returns those shaped-blob bounds. Use
/// [drawOriginForBounds] / [baselineForVAlignWithBounds] so `y` is the correct
/// blob origin for vertical centering.
///
/// Horizontal width still uses [FontMetrics.horizontalAdvance] (blob width is
/// inflated and must not drive layout).
///
/// ## Qt map
/// | Qt | window_toolkit |
/// |----|----------------|
/// | `QPainter::drawText(QRect, flags, text)` | [TextLayout.drawInRect] / [PainterFont.drawTextInRect] |
/// | `Qt::AlignVCenter \| AlignLeft` | [TextAlign.leftCenter] |
/// | `QFontMetrics::horizontalAdvance` | [FontMetrics.horizontalAdvance] |
/// | `QFontMetrics::elidedText` | [FontMetrics.elidedText] / [TextLayout.elide] |
/// | `QTextOption` | [TextOption] |
class TextLayout {
  TextLayout._();

  // ── Draw-origin math ────────────────────────────────────────────────

  /// Draw origin y for **baseline-relative** em metrics (ascent/descent).
  ///
  /// Prefer [drawOriginForBounds] with shaped-blob bounds for Skia bar text.
  static double baselineInBox(
    double boxTop,
    double boxHeight, {
    required double ascent,
    required double descent,
  }) {
    if (boxHeight <= 0) return boxTop;
    return boxTop + (boxHeight + ascent - descent) / 2.0;
  }

  /// [baselineInBox] using [FontMetrics] for [font].
  static double baselineForFont(
    double boxTop,
    double boxHeight,
    Font font,
  ) {
    final m = FontDatabase.instance.metrics(font);
    return baselineInBox(
      boxTop,
      boxHeight,
      ascent: m.ascent,
      descent: m.descent,
    );
  }

  /// Draw origin that centers glyph [bounds] (relative to draw origin) in a box.
  ///
  /// For shaped Skia blobs (`top≈0`): origin is line top → centers the line box.
  /// For baseline metrics (`top≈-ascent`): origin is baseline → centers ink.
  static double drawOriginForBounds(
    double boxTop,
    double boxHeight,
    Rect bounds,
  ) {
    if (boxHeight <= 0) return boxTop - bounds.top;
    final inkMid = (bounds.top + bounds.bottom) / 2.0;
    return boxTop + boxHeight / 2.0 - inkMid;
  }

  /// Alias for [drawOriginForBounds].
  static double baselineForBounds(
    double boxTop,
    double boxHeight,
    Rect bounds,
  ) =>
      drawOriginForBounds(boxTop, boxHeight, bounds);

  /// Optional extra lift (px). Keep 0 when using shaped-blob bounds.
  static double opticalLift = 0.0;

  /// Draw origin for [TextVAlign] using font em metrics.
  static double baselineForVAlign(
    double boxTop,
    double boxHeight,
    TextVAlign vAlign, {
    required double ascent,
    required double descent,
    double? lift,
  }) {
    final up = lift ?? opticalLift;
    switch (vAlign) {
      case TextVAlign.top:
        return boxTop + ascent;
      case TextVAlign.center:
        return baselineInBox(
              boxTop,
              boxHeight,
              ascent: ascent,
              descent: descent,
            ) -
            up;
      case TextVAlign.bottom:
        return boxTop + boxHeight - descent;
      case TextVAlign.baselineCenter:
        return boxTop + boxHeight / 2.0 - up;
    }
  }

  /// Draw origin for [TextVAlign] using shaped glyph [bounds] (correct for Skia).
  static double baselineForVAlignWithBounds(
    double boxTop,
    double boxHeight,
    TextVAlign vAlign,
    Rect bounds, {
    double? lift,
  }) {
    final up = lift ?? opticalLift;
    switch (vAlign) {
      case TextVAlign.top:
        return boxTop - bounds.top;
      case TextVAlign.center:
        return drawOriginForBounds(boxTop, boxHeight, bounds) - up;
      case TextVAlign.bottom:
        return boxTop + boxHeight - bounds.bottom;
      case TextVAlign.baselineCenter:
        return boxTop + boxHeight / 2.0 - up;
    }
  }

  /// Line box height (ascent + descent + leading).
  static double lineHeight(Font font) {
    return lineHeightOf(FontDatabase.instance.metrics(font));
  }

  static double lineHeightOf(FontMetrics m) {
    final h = m.ascent + m.descent + m.leading;
    return h > 0 ? h : m.font.pixelSize * 1.2;
  }

  // ── Elide (Qt::TextElideMode) ───────────────────────────────────────

  static String elide(
    String text,
    double maxWidth,
    FontMetrics metrics, {
    TextElideMode mode = TextElideMode.right,
    String ellipsis = '…',
  }) {
    if (mode == TextElideMode.none) return text;
    if (metrics.horizontalAdvance(text) <= maxWidth) return text;
    final ellipsisW = metrics.horizontalAdvance(ellipsis);
    if (ellipsisW >= maxWidth) return ellipsis;

    switch (mode) {
      case TextElideMode.none:
        return text;
      case TextElideMode.right:
        return metrics.elidedText(text, maxWidth, ellipsis: ellipsis);
      case TextElideMode.left:
        return _elideLeft(text, maxWidth, metrics, ellipsis, ellipsisW);
      case TextElideMode.middle:
        return _elideMiddle(text, maxWidth, metrics, ellipsis, ellipsisW);
    }
  }

  static String _elideLeft(
    String text,
    double maxWidth,
    FontMetrics metrics,
    String ellipsis,
    double ellipsisW,
  ) {
    final target = maxWidth - ellipsisW;
    var lo = 0;
    var hi = text.length;
    while (lo < hi) {
      final mid = (lo + hi) >> 1;
      final suffix = text.substring(mid);
      if (metrics.horizontalAdvance(suffix) <= target) {
        hi = mid;
      } else {
        lo = mid + 1;
      }
    }
    return '$ellipsis${text.substring(lo)}';
  }

  static String _elideMiddle(
    String text,
    double maxWidth,
    FontMetrics metrics,
    String ellipsis,
    double ellipsisW,
  ) {
    final target = maxWidth - ellipsisW;
    if (target <= 0) return ellipsis;
    // Binary search how many characters to keep (split L/R).
    var keep = 0;
    var lo = 0;
    var hi = text.length;
    while (lo <= hi) {
      final mid = (lo + hi) >> 1;
      final leftN = mid ~/ 2;
      final rightN = mid - leftN;
      if (leftN + rightN > text.length) {
        hi = mid - 1;
        continue;
      }
      final s =
          '${text.substring(0, leftN)}$ellipsis${text.substring(text.length - rightN)}';
      if (metrics.horizontalAdvance(s) <= maxWidth) {
        keep = mid;
        lo = mid + 1;
      } else {
        hi = mid - 1;
      }
    }
    final leftN = keep ~/ 2;
    final rightN = keep - leftN;
    if (keep <= 0) return ellipsis;
    return '${text.substring(0, leftN)}$ellipsis${text.substring(text.length - rightN)}';
  }

  // ── Layout in rectangle ─────────────────────────────────────────────

  /// Lay out a **single line** in [rect] (Qt `drawText(QRectF, flags, text)`).
  static TextLineLayout layoutInRect(
    String text,
    Rect rect, {
    required Font font,
    TextOption option = const TextOption(align: TextAlign.leftCenter),
  }) {
    final metrics = FontDatabase.instance.metrics(font);
    final maxW = option.maxWidth ?? rect.width;
    final display = elide(
      text,
      maxW,
      metrics,
      mode: option.elideMode,
      ellipsis: option.ellipsis,
    );
    final advance = metrics.horizontalAdvance(display);
    final lh = lineHeightOf(metrics);
    // Vertical: use FontMetrics bounds. For Skia these should come from the
    // shaped blob (line-top origin). Callers that paint via Painter should
    // prefer layout after a Painter.measureTextBounds probe when possible.
    final bounds = metrics.boundingRect(display.isEmpty ? 'Hg' : display);

    final x = switch (option.align.horizontal) {
      TextHAlign.left => rect.left,
      TextHAlign.center => rect.left + (rect.width - advance) / 2.0,
      TextHAlign.right => rect.left + rect.width - advance,
    };

    final originY = baselineForVAlignWithBounds(
      rect.top,
      rect.height,
      option.align.vertical,
      bounds,
    );

    return TextLineLayout(
      displayText: display,
      baseline: Offset(x, originY),
      advance: advance,
      lineHeight: lh,
      rect: rect,
    );
  }

  /// Lay out multi-line text (`\n` separated) in [rect], aligning the block.
  static TextBlockLayout layoutBlockInRect(
    String text,
    Rect rect, {
    required Font font,
    TextOption option = const TextOption(align: TextAlign.topLeft),
  }) {
    final metrics = FontDatabase.instance.metrics(font);
    final rawLines = text.split('\n');
    final lineGap = font.pixelSize * option.lineGapFactor;
    final lh = lineHeightOf(metrics);
    final maxW = option.maxWidth ?? rect.width;

    final prepared = <String>[];
    var contentW = 0.0;
    for (final raw in rawLines) {
      final line = raw.isEmpty ? ' ' : raw;
      final display = elide(
        line,
        maxW,
        metrics,
        mode: option.elideMode,
        ellipsis: option.ellipsis,
      );
      prepared.add(display);
      final a = metrics.horizontalAdvance(display);
      if (a > contentW) contentW = a;
    }

    final contentH = prepared.isEmpty
        ? 0.0
        : prepared.length * lh +
            (prepared.length - 1).clamp(0, 1000) * lineGap;

    // Block origin (top of first line box) from vertical align.
    double blockTop;
    switch (option.align.vertical) {
      case TextVAlign.top:
      case TextVAlign.baselineCenter:
        blockTop = rect.top;
      case TextVAlign.center:
        blockTop = rect.top + (rect.height - contentH) / 2.0;
      case TextVAlign.bottom:
        blockTop = rect.top + rect.height - contentH;
    }

    final lines = <TextLineLayout>[];
    var y = blockTop;
    for (final display in prepared) {
      final advance = metrics.horizontalAdvance(display);
      final x = switch (option.align.horizontal) {
        TextHAlign.left => rect.left,
        TextHAlign.center => rect.left + (rect.width - advance) / 2.0,
        TextHAlign.right => rect.left + rect.width - advance,
      };
      final baselineY = baselineInBox(
        y,
        lh,
        ascent: metrics.ascent,
        descent: metrics.descent,
      );
      lines.add(
        TextLineLayout(
          displayText: display,
          baseline: Offset(x, baselineY),
          advance: advance,
          lineHeight: lh,
          rect: Rect.fromLTWH(rect.left, y, rect.width, lh),
        ),
      );
      y += lh + lineGap;
    }

    return TextBlockLayout(
      lines: lines,
      rect: rect,
      contentWidth: contentW,
      contentHeight: contentH,
    );
  }

  /// Draw single-line text in [rect] with [option] alignment.
  static TextLineLayout drawInRect(
    Painter painter,
    String text,
    Rect rect, {
    required Font font,
    TextOption option = const TextOption(align: TextAlign.leftCenter),
    Color? color,
  }) {
    final layout = layoutInRect(text, rect, font: font, option: option);
    painter.drawTextFont(
      layout.displayText,
      layout.baseline,
      font: font,
      color: color,
    );
    return layout;
  }

  /// Draw multi-line text in [rect].
  static TextBlockLayout drawBlockInRect(
    Painter painter,
    String text,
    Rect rect, {
    required Font font,
    TextOption option = const TextOption(align: TextAlign.topLeft),
    Color? color,
  }) {
    final layout =
        layoutBlockInRect(text, rect, font: font, option: option);
    for (final line in layout.lines) {
      painter.drawTextFont(
        line.displayText,
        line.baseline,
        font: font,
        color: color,
      );
    }
    return layout;
  }
}
