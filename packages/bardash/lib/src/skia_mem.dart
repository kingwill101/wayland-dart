/// Periodic Skia cache purging via FFI.
library;

import 'dart:ffi';
import 'dart:io' show Platform;

DynamicLibrary? _skiaLib;

DynamicLibrary _getSkia() {
  if (_skiaLib != null) return _skiaLib!;
  // Try the bundle's lib directory first.
  try {
    // AOT bundle layout: bin/bardash + lib/libskia_dart.so
    final script = Platform.script;
    final dir = script.resolve('..').toFilePath();              // .../bundle/bin/
    final bundle = '${dir}../lib/libskia_dart.so';              // .../bundle/lib/libskia_dart.so
    _skiaLib = DynamicLibrary.open(bundle);
    return _skiaLib!;
  } catch (_) {}
  // Fallback: process symbols (JIT / dart run).
  try {
    _skiaLib = DynamicLibrary.process();
    return _skiaLib!;
  } catch (_) {}
  throw UnsupportedError('Cannot load Skia shared library');
}

/// Purges Skia caches (font, glyph, resource, HarfBuzz shaper).
void purgeSkiaCaches() {
  try {
    final lib = _getSkia();
    { // Purge all Skia graphics caches
      final ptr = lib.lookup<NativeFunction<Void Function()>>(
        'sk_graphics_purge_all_caches',
      );
      ptr.asFunction<void Function()>()();
    }
    { // Purge HarfBuzz shaper cache
      final ptr = lib.lookup<NativeFunction<Void Function()>>(
        'sk_shaper_hb_purge_caches',
      );
      ptr.asFunction<void Function()>()();
    }
  } catch (_) {}
}

/// Returns Skia font cache usage in bytes.
int skiaFontCacheUsed() {
  try {
    final lib = _getSkia();
    final ptr = lib.lookup<NativeFunction<Int64 Function()>>(
      'sk_graphics_get_font_cache_used',
    );
    final fn = ptr.asFunction<int Function()>();
    return fn();
  } catch (_) {
    return 0;
  }
}

/// Set Skia font cache limit in bytes. Smaller limit keeps RSS bounded.
void skiaSetFontCacheLimit(int bytes) {
  try {
    final lib = _getSkia();
    final ptr = lib.lookup<NativeFunction<Int64 Function(Int64)>>(
      'sk_graphics_set_font_cache_limit',
    );
    ptr.asFunction<int Function(int)>()(bytes);
  } catch (_) {}
}

/// Returns Skia font cache limit in bytes.
int skiaFontCacheLimit() {
  try {
    final lib = _getSkia();
    final ptr = lib.lookup<NativeFunction<Int64 Function()>>(
      'sk_graphics_get_font_cache_limit',
    );
    final fn = ptr.asFunction<int Function()>();
    return fn();
  } catch (_) {
    return 0;
  }
}
