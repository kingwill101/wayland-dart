import 'package:layout_engine/layout_engine.dart' as le;

import '../font/font_database.dart';
import '../font/font.dart';

/// [le.TextMeasure] implementation backed by window_toolkit's [FontDatabase].
///
/// Measures text using Skia font metrics via the toolkit's font engine.
class WtTextMeasure extends le.TextMeasure {
  final double _fontSize;
  final String _fontFamily;

  WtTextMeasure({double fontSize = 14, String fontFamily = 'sans'})
    : _fontSize = fontSize,
      _fontFamily = fontFamily;

  @override
  double textWidth(String text) {
    try {
      final font = Font(family: _fontFamily, pixelSize: _fontSize);
      return FontDatabase.instance.metrics(font).horizontalAdvance(text);
    } catch (_) {
      return text.length * _fontSize * 0.6;
    }
  }

  @override
  double get lineHeight {
    try {
      final font = Font(family: _fontFamily, pixelSize: _fontSize);
      return FontDatabase.instance.metrics(font).height;
    } catch (_) {
      return _fontSize * 1.2;
    }
  }
}
