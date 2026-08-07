// Bardash icon shim Dart wrapper — native GTK + librsvg via Native Assets
// Replaces manual _parseIndexTheme/_findIconInDirs + rsvg-convert subprocess.

import 'dart:ffi' as ffi;
import 'dart:io';
import 'package:ffi/ffi.dart';

import 'ffigen_icon.dart';

class IconShim {
  static IconShimBindings? _bindings;
  static bool _tried = false;

  static IconShimBindings? get bindings {
    if (_tried) return _bindings;
    _tried = true;
    try {
      // Native Assets provide libicon_shim.so via CodeAsset lookup
      // Fallback to manual dlopen if CodeAsset path not resolved
      final lib = _openLibrary();
      _bindings = IconShimBindings(lib);
      // probe version to verify
      _bindings!.icon_shim_version();
    } catch (_) {
      _bindings = null;
    }
    return _bindings;
  }

  static ffi.DynamicLibrary _openLibrary() {
    // CodeAsset loader: dart's native assets expose via DynamicLibrary.open on Linux
    // The asset file is libicon_shim.so in .dart_tool/lib
    // Try standard locations relative to package root
    const names = ['libicon_shim.so', 'libicon_shim.dylib', 'icon_shim.dll'];
    for (final n in names) {
      try {
        return ffi.DynamicLibrary.open(n);
      } catch (_) {}
    }
    // Native Assets via code_assets still loads via ffi.DynamicLibrary
    // Last resort: process
    return ffi.DynamicLibrary.process();
  }

  /// Lookup icon via GTK icon theme, returns absolute path or null.
  static String? lookup(String name, {int size = 32, String? theme}) {
    final b = bindings;
    if (b == null || name.isEmpty) return null;
    final cName = name.toNativeUtf8();
    final cTheme = theme != null ? theme.toNativeUtf8() : ffi.nullptr.cast<ffi.Char>();
    try {
      final ptr = b.icon_shim_lookup(cName.cast<ffi.Char>(), size, cTheme.cast<ffi.Char>());
      if (ptr == ffi.nullptr) return null;
      final dartStr = ptr.cast<Utf8>().toDartString();
      b.icon_shim_free_string(ptr);
      if (dartStr.isEmpty || !File(dartStr).existsSync()) return null;
      return dartStr;
    } finally {
      calloc.free(cName);
      if (cTheme != ffi.nullptr) calloc.free(cTheme);
    }
  }

  /// Raster SVG to PNG at w×h via librsvg+cairo, returns true on success.
  static bool rasterSvg(String svgPath, String pngPath, {int w = 32, int h = 32}) {
    final b = bindings;
    if (b == null) return false;
    final cSvg = svgPath.toNativeUtf8();
    final cPng = pngPath.toNativeUtf8();
    try {
      final rc = b.icon_shim_raster_svg(cSvg.cast<ffi.Char>(), cPng.cast<ffi.Char>(), w, h);
      return rc == 0 && File(pngPath).existsSync();
    } finally {
      calloc.free(cSvg);
      calloc.free(cPng);
    }
  }

  static bool get isAvailable => bindings != null;
}
