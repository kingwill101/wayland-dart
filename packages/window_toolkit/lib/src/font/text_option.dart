import 'text_align.dart';

/// Options for laying out / drawing a string — Qt [QTextOption] lite.
class TextOption {
  /// Alignment inside the target rectangle.
  final TextAlign align;

  /// How to shorten text that does not fit [maxWidth] / the rect width.
  final TextElideMode elideMode;

  /// Ellipsis glyph when eliding (default `…`).
  final String ellipsis;

  /// Optional hard max width in device pixels (in addition to the rect).
  final double? maxWidth;

  /// Line gap as a fraction of font size when drawing multi-line text.
  final double lineGapFactor;

  const TextOption({
    this.align = TextAlign.topLeft,
    this.elideMode = TextElideMode.none,
    this.ellipsis = '…',
    this.maxWidth,
    this.lineGapFactor = 0.25,
  });

  /// Centered single-line UI label (buttons, chips, bar modules).
  static const center = TextOption(align: TextAlign.center);

  /// Left-aligned, vertically centered (status bar modules, menu rows).
  static const leftCenter = TextOption(align: TextAlign.leftCenter);

  /// Elide at end, left + v-center (window titles).
  static const elideEndLeftCenter = TextOption(
    align: TextAlign.leftCenter,
    elideMode: TextElideMode.right,
  );

  TextOption copyWith({
    TextAlign? align,
    TextElideMode? elideMode,
    String? ellipsis,
    double? maxWidth,
    double? lineGapFactor,
  }) {
    return TextOption(
      align: align ?? this.align,
      elideMode: elideMode ?? this.elideMode,
      ellipsis: ellipsis ?? this.ellipsis,
      maxWidth: maxWidth ?? this.maxWidth,
      lineGapFactor: lineGapFactor ?? this.lineGapFactor,
    );
  }
}
