import 'dart:convert';

import 'package:skia_dart/skia_dart.dart';

import '../drawing/color.dart';
import 'painter.dart';

/// Shared Skia text pipeline for the process.
///
/// Font managers and shaped blobs are expensive. One engine is reused by every
/// painter; shape results (including [SkTextBlob]) are cached by
/// (text, size, family) so bar redraws after the first frame avoid
/// `sk_shaper_shape`.
class SkiaTextEngine {
  static final SkiaTextEngine shared = SkiaTextEngine._();

  SkFontMgr? _fontMgr;
  SkUnicode? _unicode;
  SkShaper? _shaper;
  final Map<String, SkTypeface> _typefaces = {};
  final Map<String, _ShapeCacheEntry> _shapeCache = {};
  static const _maxCacheEntries = 384;

  SkiaTextEngine._();

  factory SkiaTextEngine() => shared;

  SkFontMgr? get _platformFontMgr =>
      _fontMgr ??= SkFontMgr.createPlatformDefault();

  void _ensureShaper() {
    _fontMgr ??= SkFontMgr.createPlatformDefault();
    _unicode ??= SkUnicode.icu();
    _shaper ??= _unicode != null
        ? SkShaper.harfbuzzShapeDontWrapOrReorder(_unicode!, fallback: _fontMgr)
        : SkShaper.primitive();
    _shaper ??= SkShaper.primitive();
  }

  SkTypeface _typefaceFor(String fontFamily) {
    return _typefaces.putIfAbsent(fontFamily, () {
      final mgr = _platformFontMgr;
      return mgr?.matchFamilyStyle(fontFamily, SkFontStyle.normal()) ??
          SkTypeface.empty();
    });
  }

  SkFont _fontFor(String fontFamily, double size) {
    return SkFont(typeface: _typefaceFor(fontFamily), size: size);
  }

  static String _cacheKey(String text, double size, String fontFamily) =>
      '$fontFamily|${size.toStringAsFixed(2)}|$text';

  _ShapeCacheEntry _shapeCached(
    String text, {
    required double size,
    String fontFamily = 'sans',
  }) {
    final key = _cacheKey(text, size, fontFamily);
    final hit = _shapeCache[key];
    if (hit != null) return hit;

    final shaped = _shapeText(text, size: size, fontFamily: fontFamily);
    final entry = _ShapeCacheEntry(
      advance: shaped.advance,
      bounds: shaped.bounds,
      blob: shaped.blob,
    );

    if (_shapeCache.length >= _maxCacheEntries) {
      final keys = _shapeCache.keys.take(_maxCacheEntries ~/ 2).toList();
      for (final k in keys) {
        _shapeCache.remove(k)?.dispose();
      }
    }
    _shapeCache[key] = entry;
    return entry;
  }

  ({SkTextBlob? blob, double advance, Rect bounds}) _shapeText(
    String text, {
    required double size,
    String fontFamily = 'sans',
  }) {
    final utf8Bytes = utf8.encode(text).length;
    if (utf8Bytes == 0) {
      return (
        blob: null,
        advance: 0,
        bounds: Rect.fromLTWH(0, -size * 0.8, 0, size),
      );
    }

    _ensureShaper();

    final font = _fontFor(fontFamily, size);
    // Typographic advance from SkFont — reliable. Shaper endPoint.x is often
    // stuck at 0 with harfbuzzShapeDontWrapOrReorder, and textblob bounds can
    // be ~2× wider than the real advance (caused huge bar module gaps).
    final fontMeasure = font.measureText(
      SkEncodedText.string(text),
      includeBounds: true,
    );
    final fontAdvance = fontMeasure.advance;
    final fontBounds = fontMeasure.bounds;

    final fontIterator = _fontMgr != null
        ? SkFontRunIterator(text, font, fallback: _fontMgr!)
        : SkFontRunIterator.trivial(font, utf8Bytes: utf8Bytes);
    final bidiIterator = _unicode != null
        ? SkBiDiRunIterator.unicode(_unicode!, text) ??
              SkBiDiRunIterator.trivial(bidiLevel: 0, utf8Bytes: utf8Bytes)
        : SkBiDiRunIterator.trivial(bidiLevel: 0, utf8Bytes: utf8Bytes);
    final scriptIterator = _unicode != null
        ? SkScriptRunIterator.harfBuzz(text) ??
              SkScriptRunIterator.trivial(
                script: 0x4C61746E,
                utf8Bytes: utf8Bytes,
              )
        : SkScriptRunIterator.trivial(script: 0x4C61746E, utf8Bytes: utf8Bytes);
    final languageIterator = _unicode != null
        ? SkLanguageRunIterator(text)
        : SkLanguageRunIterator.trivial('en', utf8Bytes: utf8Bytes);
    final handler = SkTextBlobBuilderRunHandler(text, SkPoint(0, 0));

    try {
      _shaper!.shape(
        text,
        fontIterator: fontIterator,
        bidiIterator: bidiIterator,
        scriptIterator: scriptIterator,
        languageIterator: languageIterator,
        width: double.infinity,
        handler: handler,
      );

      final blob = handler.makeBlob();
      final shapedAdvance = handler.endPoint.x;
      // Horizontal advance: SkFont (shaper endPoint.x is often 0 with
      // DontWrapOrReorder). Do NOT use blob.bounds.width — it is inflated.
      final advance =
          shapedAdvance > 0.5 ? shapedAdvance : fontAdvance;

      // Vertical placement MUST use blob.bounds: harfbuzzShapeDontWrapOrReorder
      // builds blobs whose origin is the **line-box top** (top≈0, bottom≈lineH),
      // NOT the alphabetic baseline. Font.measureText bounds are baseline-
      // relative (top≈-ascent) — using those for drawY treated the origin as
      // baseline and parked text on the bottom of the bar.
      Rect bounds;
      if (blob != null) {
        final b = blob.bounds;
        bounds = Rect.fromLTRB(b.left, b.top, b.right, b.bottom);
      } else if (fontBounds != null) {
        bounds = Rect.fromLTRB(
          fontBounds.left,
          fontBounds.top,
          fontBounds.right,
          fontBounds.bottom,
        );
      } else {
        bounds = Rect.fromLTWH(0, 0, advance, size);
      }
      return (blob: blob, advance: advance, bounds: bounds);
    } finally {
      handler.dispose();
      languageIterator.dispose();
      scriptIterator.dispose();
      bidiIterator.dispose();
      fontIterator.dispose();
      font.dispose();
    }
  }

  void drawText(
    SkCanvas canvas,
    String text,
    double x,
    double y, {
    Color? color,
    double size = 14,
    String fontFamily = 'sans',
  }) {
    final entry = _shapeCached(text, size: size, fontFamily: fontFamily);
    final blob = entry.blob;
    if (blob == null) return;

    final paint = SkPaint();
    paint.isAntiAlias = true;
    paint.color = color != null
        ? SkColor(color.toArgb8888())
        : SkColor(0xffc8c8c8);

    try {
      // Blob is owned by the cache — do not dispose after draw.
      canvas.drawTextBlob(blob, x, y, paint);
    } finally {
      paint.dispose();
    }
  }

  Size measureText(
    String text, {
    double size = 14,
    String fontFamily = 'sans',
  }) {
    // Layout width must be the typographic advance, not ink bounds.
    // Blob bounds can be much wider than the advance (font padding / fallback
    // glyphs), which left multi-dozen-pixel holes between bar modules.
    final e = _shapeCached(text, size: size, fontFamily: fontFamily);
    final h = e.bounds.height > 0 ? e.bounds.height : size;
    return Size(e.advance, h);
  }

  Rect measureTextBounds(
    String text, {
    double size = 14,
    String fontFamily = 'sans',
  }) {
    return _shapeCached(text, size: size, fontFamily: fontFamily).bounds;
  }

  /// Typographic advance (where the next glyph would start).
  double measureTextAdvance(
    String text, {
    double size = 14,
    String fontFamily = 'sans',
  }) {
    return _shapeCached(text, size: size, fontFamily: fontFamily).advance;
  }

  void dispose() {}

  void disposeShared() {
    for (final e in _shapeCache.values) {
      e.dispose();
    }
    _shapeCache.clear();
    for (final typeface in _typefaces.values) {
      typeface.dispose();
    }
    _typefaces.clear();
    _shaper?.dispose();
    _shaper = null;
    _unicode?.dispose();
    _unicode = null;
    _fontMgr?.dispose();
    _fontMgr = null;
  }
}

class _ShapeCacheEntry {
  final double advance;
  final Rect bounds;
  final SkTextBlob? blob;

  _ShapeCacheEntry({
    required this.advance,
    required this.bounds,
    required this.blob,
  });

  void dispose() {
    blob?.dispose();
  }
}
