import 'font.dart';
import 'font_info.dart';
import 'font_metrics.dart';

/// Backend interface for font resolution and metrics — Qt platform font DB +
/// engine analogue (`QPlatformFontDatabase` / font engine).
///
/// Implementations: Skia (HarfBuzz + SkFontMgr), bitmap (fixed-cell), tests.
///
/// Prefer **extending** [FontEngineBase] so optional methods have defaults
/// (Dart `implements` does not inherit concrete members).
abstract class FontEngine {
  /// Stable id for debugging (`skia`, `bitmap`, …).
  String get id;

  /// List available family names (may be empty if the backend cannot enumerate).
  List<String> families();

  /// Styles for [family] (e.g. `Regular`, `Bold`). Empty if unknown.
  List<String> styles(String family);

  /// Whether [family] is primarily fixed-pitch.
  bool isFixedPitch(String family);

  /// Resolve [request] to the face the backend will use.
  FontInfo resolve(Font request);

  /// Metrics for measuring strings with [request] (resolved internally).
  FontMetrics metrics(Font request);

  /// Optional: register a font file; returns a family name or null.
  String? addApplicationFont(String filePath);

  /// Release backend caches (typefaces, shape caches if owned here).
  void dispose();
}

/// Default stubs for optional [FontEngine] methods.
abstract class FontEngineBase implements FontEngine {
  @override
  String? addApplicationFont(String filePath) => null;

  @override
  void dispose() {}
}
