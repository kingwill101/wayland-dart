import '../painter/painter.dart' show Rect, Size;
import 'font.dart';

/// Font metrics — Qt [QFontMetricsF]-inspired.
///
/// Prefer [horizontalAdvance] for layout width (like QFontMetrics::horizontalAdvance).
/// Use [boundingRect] / [tightBoundingRect] only for optical centering.
class FontMetrics {
  final Font font;
  final double ascent;
  final double descent;
  final double leading;
  final double height;
  final double averageCharWidth;
  final double maxCharWidth;
  final bool fixedPitch;

  /// Backend-specific measure callback for string advances / bounds.
  final double Function(String text) _advanceOf;
  final Rect Function(String text) _boundsOf;
  final Rect Function(String text) _tightBoundsOf;

  FontMetrics({
    required this.font,
    required this.ascent,
    required this.descent,
    required this.leading,
    required this.height,
    required this.averageCharWidth,
    required this.maxCharWidth,
    required this.fixedPitch,
    required double Function(String text) horizontalAdvance,
    required Rect Function(String text) boundingRect,
    Rect Function(String text)? tightBoundingRect,
  })  : _advanceOf = horizontalAdvance,
        _boundsOf = boundingRect,
        _tightBoundsOf = tightBoundingRect ?? boundingRect;

  /// Typographic width for layout (QFontMetrics::horizontalAdvance).
  double horizontalAdvance(String text) => _advanceOf(text);

  /// Alias used by older Qt code (`width` was deprecated for advance).
  double width(String text) => horizontalAdvance(text);

  /// Ink/layout bounds relative to baseline origin (may be looser than tight).
  Rect boundingRect(String text) => _boundsOf(text);

  /// Tight glyph ink bounds when the backend can provide them.
  Rect tightBoundingRect(String text) => _tightBoundsOf(text);

  Size size(String text) {
    final a = horizontalAdvance(text);
    return Size(a, height);
  }

  /// Elide [text] to fit [maxWidth] with an ellipsis (Qt elidedText lite).
  String elidedText(String text, double maxWidth, {String ellipsis = '…'}) {
    if (horizontalAdvance(text) <= maxWidth) return text;
    final ellipsisW = horizontalAdvance(ellipsis);
    if (ellipsisW >= maxWidth) return ellipsis;
    final target = maxWidth - ellipsisW;
    var lo = 0;
    var hi = text.length;
    while (lo < hi) {
      final mid = (lo + hi + 1) >> 1;
      if (horizontalAdvance(text.substring(0, mid)) <= target) {
        lo = mid;
      } else {
        hi = mid - 1;
      }
    }
    return '${text.substring(0, lo)}$ellipsis';
  }
}
