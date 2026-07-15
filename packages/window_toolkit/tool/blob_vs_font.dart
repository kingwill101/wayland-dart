import 'package:skia_dart/skia_dart.dart';
import 'package:window_toolkit/src/painter/skia_text_engine.dart';

void main() {
  final e = SkiaTextEngine.shared;
  e.measureTextAdvance('Apps', size: 13, fontFamily: 'sans');
  final b = e.measureTextBounds('Apps', size: 13, fontFamily: 'sans');
  print('cached bounds: LTRB=${b.left},${b.top},${b.right},${b.bottom}');

  final fontMgr = SkFontMgr.createPlatformDefault()!;
  final face =
      fontMgr.matchFamilyStyle('sans', SkFontStyle.normal()) ?? SkTypeface.empty();
  final font = SkFont(typeface: face, size: 13);
  final fm = font.measureText(SkEncodedText.string('Apps'), includeBounds: true);
  print('font.measureText advance=${fm.advance} bounds LTRB='
      '${fm.bounds?.left},${fm.bounds?.top},${fm.bounds?.right},${fm.bounds?.bottom}');

  final unicode = SkUnicode.icu();
  final shaper =
      SkShaper.harfbuzzShapeDontWrapOrReorder(unicode!, fallback: fontMgr)!;
  final handler = SkTextBlobBuilderRunHandler('Apps', SkPoint(0, 0));
  final fi = SkFontRunIterator('Apps', font, fallback: fontMgr);
  final bi = SkBiDiRunIterator.trivial(bidiLevel: 0, utf8Bytes: 4);
  final si = SkScriptRunIterator.trivial(script: 0x4C61746E, utf8Bytes: 4);
  final li = SkLanguageRunIterator.trivial('en', utf8Bytes: 4);
  shaper.shape(
    'Apps',
    fontIterator: fi,
    bidiIterator: bi,
    scriptIterator: si,
    languageIterator: li,
    width: double.infinity,
    handler: handler,
  );
  final blob = handler.makeBlob();
  if (blob != null) {
    final bb = blob.bounds;
    print('blob.bounds LTRB=${bb.left},${bb.top},${bb.right},${bb.bottom}');
    print('endPoint=${handler.endPoint.x},${handler.endPoint.y}');
  } else {
    print('null blob');
  }
}
