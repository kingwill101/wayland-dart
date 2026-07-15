import 'package:skia_dart/skia_dart.dart';

import '../painter/skia_text_engine.dart';
import 'font.dart';
import 'font_engine.dart';
import 'font_info.dart';
import 'font_metrics.dart';

/// Skia / HarfBuzz font backend — production path for Wayland UI.
///
/// Uses platform [SkFontMgr] for matching and [SkiaTextEngine] for shaped
/// measure/draw (shared typeface + shape caches).
class SkiaFontEngine extends FontEngineBase {
  SkiaFontEngine({SkiaTextEngine? textEngine})
      : _text = textEngine ?? SkiaTextEngine.shared;

  final SkiaTextEngine _text;
  SkFontMgr? _mgr;
  final Map<String, SkTypeface> _faces = {};
  /// Families registered via [addApplicationFont] (path → family name).
  final Map<String, String> _appFonts = {};
  List<String>? _familyCache;

  SkFontMgr get _fontMgr =>
      _mgr ??= SkFontMgr.createPlatformDefault() ?? SkFontMgr.empty();

  @override
  String get id => 'skia';

  @override
  List<String> families() {
    if (_familyCache != null) {
      return List<String>.from(_familyCache!);
    }
    final names = <String>{
      'sans',
      'serif',
      'monospace',
      ..._appFonts.values,
    };
    try {
      final n = _fontMgr.countFamilies();
      // Cap enumeration cost on huge system font sets.
      final limit = n > 512 ? 512 : n;
      for (var i = 0; i < limit; i++) {
        final name = _fontMgr.getFamilyName(i);
        if (name.isNotEmpty) names.add(name);
      }
    } catch (_) {
      names.addAll(const [
        'Noto Sans',
        'Noto Color Emoji',
        'Hack Nerd Font',
        'Font Awesome 7 Free',
      ]);
    }
    _familyCache = names.toList()..sort();
    return List<String>.from(_familyCache!);
  }

  @override
  List<String> styles(String family) {
    try {
      final set = _fontMgr.matchFamily(family);
      if (set == null) return const ['Regular'];
      final count = set.count;
      if (count <= 0) {
        set.dispose();
        return const ['Regular'];
      }
      final out = <String>[];
      for (var i = 0; i < count && i < 32; i++) {
        final entry = set.getStyle(i);
        final name = entry.name;
        out.add(name != null && name.isNotEmpty ? name : 'Style$i');
      }
      set.dispose();
      return out.isEmpty ? const ['Regular'] : out;
    } catch (_) {
      return const ['Regular', 'Bold', 'Italic'];
    }
  }

  @override
  bool isFixedPitch(String family) {
    final lower = family.toLowerCase();
    return lower.contains('mono') ||
        lower.contains('courier') ||
        lower.contains('hack') ||
        lower.contains('firacode') ||
        lower.contains('jetbrains') ||
        lower.contains('consolas') ||
        lower.contains('source code');
  }

  SkFontStyle _skStyle(Font request) {
    final w = request.weight;
    if (request.italic) {
      if (w >= FontWeight.bold) return SkFontStyle.boldItalic();
      return SkFontStyle.italic();
    }
    if (w >= FontWeight.bold) return SkFontStyle.bold();
    return SkFontStyle.normal();
  }

  String _resolveFamilyName(Font request) {
    if (request.family.isNotEmpty) return request.family;
    switch (request.styleHint) {
      case FontStyleHint.serif:
        return 'serif';
      case FontStyleHint.typewriter:
        return 'monospace';
      case FontStyleHint.fantasy:
      case FontStyleHint.cursive:
      case FontStyleHint.system:
      case FontStyleHint.any:
      case FontStyleHint.sansSerif:
        return 'sans';
    }
  }

  SkTypeface _typeface(Font request) {
    final name = _resolveFamilyName(request);
    final key = '$name|${request.weight}|${request.italic}';
    return _faces.putIfAbsent(key, () {
      // Application fonts registered by path: match by reported family name.
      return _fontMgr.matchFamilyStyle(name, _skStyle(request)) ??
          SkTypeface.empty();
    });
  }

  @override
  FontInfo resolve(Font request) {
    final name = _resolveFamilyName(request);
    final face = _typeface(request);
    final exact = face.glyphCount > 0;
    final resolvedName =
        exact && face.familyName.isNotEmpty ? face.familyName : name;
    return FontInfo(
      family: resolvedName,
      pixelSize: request.pixelSize,
      weight: request.weight,
      italic: request.italic,
      fixedPitch: isFixedPitch(resolvedName),
      exactMatch: exact,
    );
  }

  @override
  FontMetrics metrics(Font request) {
    final family = _resolveFamilyName(request);
    final size = request.pixelSize;
    final face = _typeface(request);
    final skFont = SkFont(typeface: face, size: size);

    var ascent = size * 0.8;
    var descent = size * 0.2;
    var leading = 0.0;
    var avg = size * 0.5;
    var maxW = size;
    try {
      final gm = skFont.getMetrics(includeMetrics: true);
      final m = gm.metrics;
      if (m != null) {
        ascent = m.ascent.abs();
        descent = m.descent.abs();
        leading = m.leading.abs();
        if (m.avgCharWidth > 0) avg = m.avgCharWidth;
        if (m.maxCharWidth > 0) maxW = m.maxCharWidth;
      } else if (gm.spacing > 0) {
        ascent = gm.spacing * 0.8;
        descent = gm.spacing * 0.2;
      }
    } catch (_) {}

    final metricsHeight =
        (ascent + descent + leading).clamp(size * 0.5, size * 4.0);

    skFont.dispose();

    return FontMetrics(
      font: request.copyWith(family: family),
      ascent: ascent,
      descent: descent,
      leading: leading,
      height: metricsHeight,
      averageCharWidth: avg,
      maxCharWidth: maxW,
      fixedPitch: isFixedPitch(family),
      horizontalAdvance: (text) => _text.measureTextAdvance(
        text,
        size: size,
        fontFamily: family,
      ),
      // Shaped-blob bounds (line-top origin) — required for drawText v-center.
      boundingRect: (text) => _text.measureTextBounds(
        text,
        size: size,
        fontFamily: family,
      ),
      tightBoundingRect: (text) => _text.measureTextBounds(
        text,
        size: size,
        fontFamily: family,
      ),
    );
  }

  @override
  String? addApplicationFont(String filePath) {
    try {
      final face = _fontMgr.createFromFile(filePath);
      if (face == null || face.glyphCount <= 0) return null;
      final name = face.familyName.isNotEmpty
          ? face.familyName
          : filePath.split('/').last;
      _appFonts[filePath] = name;
      // Keep face alive under a stable key so matchFamilyStyle can find it
      // after registration — also insert into cache for direct use.
      _faces['$name|${FontWeight.normal}|false'] = face;
      _familyCache = null;
      return name;
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    for (final f in _faces.values) {
      f.dispose();
    }
    _faces.clear();
    _appFonts.clear();
    _familyCache = null;
    _mgr?.dispose();
    _mgr = null;
  }
}
