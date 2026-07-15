import 'package:skia_dart/skia_dart.dart';

import 'bitmap_font_engine.dart';
import 'font.dart';
import 'font_engine.dart';
import 'font_info.dart';
import 'font_metrics.dart';
import 'skia_font_engine.dart';

/// Application-wide font database — Qt [QFontDatabase] + app font settings.
///
/// ```dart
/// // Pick backend (default: skia when available, else bitmap)
/// FontDatabase.instance.useEngine(SkiaFontEngine());
///
/// // Role families (bardash / apps)
/// FontDatabase.instance.setRoleFamily(FontRole.ui, 'Noto Sans');
/// FontDatabase.instance.setRoleFamily(FontRole.icon, 'Hack Nerd Font');
/// FontDatabase.instance.setRoleFamily(FontRole.mono, 'monospace');
///
/// final m = FontDatabase.instance.metrics(Font.ui(pixelSize: 13));
/// final w = m.horizontalAdvance('Apps');
/// ```
class FontDatabase {
  FontDatabase._();

  static final FontDatabase instance = FontDatabase._();

  /// Alias used in docs / Qt mental model.
  static FontDatabase get fontDatabase => instance;

  FontEngine _engine = _defaultEngine();
  final Map<FontRole, String> _roleFamilies = {
    FontRole.ui: 'sans',
    FontRole.icon: 'sans',
    FontRole.mono: 'monospace',
  };
  /// Default UI size when a [Font] omits a positive [Font.pixelSize].
  double defaultPixelSize = 13;

  static FontEngine _defaultEngine() {
    // Prefer Skia in production; tests can inject bitmap.
    try {
      return SkiaFontEngine();
    } catch (_) {
      return BitmapFontEngine();
    }
  }

  /// Active backend (`skia`, `bitmap`, …).
  FontEngine get engine => _engine;

  String get engineId => _engine.id;

  /// Swap backend (e.g. tests → [BitmapFontEngine], production → [SkiaFontEngine]).
  void useEngine(FontEngine engine) {
    if (!identical(_engine, engine)) {
      _engine.dispose();
      _engine = engine;
    }
  }

  /// Convenience: use fixed-cell bitmap engine.
  void useBitmapEngine({BitmapFontEngine? engine}) {
    useEngine(engine ?? BitmapFontEngine());
  }

  /// Convenience: use Skia / platform font manager.
  void useSkiaEngine({SkiaFontEngine? engine}) {
    useEngine(engine ?? SkiaFontEngine());
  }

  /// Use Skia engine with an empty font manager (no FontConfig scan).
  /// Fonts must be added via [addApplicationFont] or role families will
  /// fall back to Skia's built-in typeface.
  void useSkiaEngineLight({SkiaFontEngine? engine}) {
    useEngine(engine ?? SkiaFontEngine(fontMgr: SkFontMgr.empty()));
  }

  // ── Qt QFontDatabase-style queries ──────────────────────────────────

  List<String> families() => _engine.families();

  List<String> styles(String family) => _engine.styles(family);

  bool isFixedPitch(String family) => _engine.isFixedPitch(family);

  String? addApplicationFont(String filePath) =>
      _engine.addApplicationFont(filePath);

  // ── Role / application defaults ─────────────────────────────────────

  /// Map a [FontRole] to a concrete family name.
  void setRoleFamily(FontRole role, String family) {
    _roleFamilies[role] = family;
  }

  String familyForRole(FontRole role) =>
      _roleFamilies[role] ?? _roleFamilies[FontRole.ui]!;

  Map<FontRole, String> get roleFamilies => Map.unmodifiable(_roleFamilies);

  /// Expand roles / empty family into a concrete [Font] for the engine.
  Font resolveRequest(Font request) {
    var family = request.family;
    if (request.role != null) {
      family = familyForRole(request.role!);
    }
    if (family.isEmpty) {
      family = familyForRole(FontRole.ui);
    }
    final size =
        request.pixelSize > 0 ? request.pixelSize : defaultPixelSize;
    return request.copyWith(family: family, pixelSize: size);
  }

  FontInfo fontInfo(Font request) => _engine.resolve(resolveRequest(request));

  FontMetrics metrics(Font request) =>
      _engine.metrics(resolveRequest(request));

  /// Shortcut: metrics for a role at [pixelSize].
  FontMetrics metricsForRole(FontRole role, {double? pixelSize}) {
    return metrics(Font(
      role: role,
      pixelSize: pixelSize ?? defaultPixelSize,
    ));
  }

  /// Horizontal advance helper (layout width).
  double horizontalAdvance(
    String text, {
    Font? font,
    String? family,
    double? pixelSize,
    FontRole? role,
  }) {
    final f = font ??
        Font(
          family: family ?? '',
          pixelSize: pixelSize ?? defaultPixelSize,
          role: role,
        );
    return metrics(f).horizontalAdvance(text);
  }

  void dispose() {
    _engine.dispose();
  }
}

/// Shorthand global accessor (Qt-style free functions live as statics on
/// [FontDatabase] in C++; here we expose a top-level getter).
FontDatabase get fontDatabase => FontDatabase.instance;
