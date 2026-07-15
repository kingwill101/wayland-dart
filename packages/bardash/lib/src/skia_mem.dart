/// Periodic Skia cache purging via FFI.
library;

import 'dart:ffi';
import 'dart:io' show Platform;

DynamicLibrary? _skiaLib;

DynamicLibrary _getSkia() {
  if (_skiaLib != null) return _skiaLib!;
  // Try the bundle's lib directory first.
  try {
    final script = Platform.script;
    final dir = script.resolve('..').toFilePath();
    _skiaLib = DynamicLibrary.open('$dir/lib/libskia_dart.so');
    return _skiaLib!;
  } catch (_) {}
  // Fallback: process symbols (JIT / dart run).
  try {
    _skiaLib = DynamicLibrary.process();
    return _skiaLib!;
  } catch (_) {}
  throw UnsupportedError('Cannot load Skia shared library');
}

/// Purges Skia caches (font, glyph, resource).
void purgeSkiaCaches() {
  try {
    final lib = _getSkia();
    final ptr = lib.lookup<NativeFunction<Void Function()>>(
      'sk_graphics_purge_all_caches',
    );
    final fn = ptr.asFunction<void Function()>();
    fn();
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
