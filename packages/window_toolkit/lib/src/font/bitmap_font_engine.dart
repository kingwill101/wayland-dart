import '../drawing/bitmap_font.dart';
import '../painter/painter.dart' show Rect;
import 'font.dart';
import 'font_engine.dart';
import 'font_info.dart';
import 'font_metrics.dart';

/// Fixed-cell bitmap font backend (raw painter / tests).
///
/// Qt analogue: a minimal platform font DB that only knows one face.
class BitmapFontEngine extends FontEngineBase {
  BitmapFontEngine({BitmapFont? font}) : _font = font ?? BitmapFont.createDefault();

  final BitmapFont _font;

  @override
  String get id => 'bitmap';

  @override
  List<String> families() => const ['bitmap', 'monospace', 'sans', 'serif'];

  @override
  List<String> styles(String family) => const ['Regular'];

  @override
  bool isFixedPitch(String family) => true;

  @override
  FontInfo resolve(Font request) {
    return FontInfo(
      family: 'bitmap',
      pixelSize: _font.charHeight.toDouble(),
      weight: FontWeight.normal,
      italic: false,
      fixedPitch: true,
      exactMatch: request.family.isEmpty ||
          families().any((f) => f.toLowerCase() == request.family.toLowerCase()),
    );
  }

  @override
  FontMetrics metrics(Font request) {
    final info = resolve(request);
    final h = _font.charHeight.toDouble();
    final cw = _font.charWidth.toDouble();
    return FontMetrics(
      font: request.copyWith(family: info.family, pixelSize: h),
      ascent: h * 0.8,
      descent: h * 0.2,
      leading: 0,
      height: h,
      averageCharWidth: cw,
      maxCharWidth: cw,
      fixedPitch: true,
      horizontalAdvance: (text) => _font.textWidth(text).toDouble(),
      // Baseline-relative bounds (top negative) so TextLayout v-center matches Skia.
      boundingRect: (text) => Rect.fromLTRB(
        0,
        -h * 0.8,
        _font.textWidth(text).toDouble(),
        h * 0.2,
      ),
    );
  }
}
