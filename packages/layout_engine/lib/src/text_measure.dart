/// Abstract text measurement strategy.
///
/// Layout widgets (RenderRow, RenderColumn, RenderPadding) need to measure
/// text to determine sizes. Different backends measure text differently:
///
/// - **window_toolkit** uses Skia font metrics (pixel-based)
/// - **artisanal** uses terminal cell widths (character-based)
/// - **Tests** can use a simple monospace approximation
///
/// Whichever backend uses this layout engine provides a [TextMeasure]
/// implementation.  The layout engine itself has no default — you must
/// set one before performing layout.
library;

/// Provider of text measurement for layout.
abstract class TextMeasure {
  /// The width of [text] in layout units (pixels, cells, etc.).
  double textWidth(String text);

  /// The height of a single line of text at the current font size.
  double get lineHeight;
}

/// Throws if no [TextMeasure] is set.
class NoTextMeasure extends TextMeasure {
  @override
  double textWidth(String text) =>
      throw StateError('No TextMeasure set. Call TextMeasureScope.set() first.');

  @override
  double get lineHeight =>
      throw StateError('No TextMeasure set. Call TextMeasureScope.set() first.');
}

/// Thread-local/global text measure scope.
///
/// ```dart
/// TextMeasureScope.set(myMeasure);
/// // ... perform layout ...
/// final w = TextMeasureScope.current.textWidth('Hello');
/// ```
class TextMeasureScope {
  static TextMeasure _current = NoTextMeasure();

  /// The active text measure.
  static TextMeasure get current => _current;

  /// Set the active text measure for the current isolate.
  static void set(TextMeasure measure) {
    _current = measure;
  }
}
