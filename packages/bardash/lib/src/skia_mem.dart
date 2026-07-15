/// Periodic Skia cache purging via FFI.
///
/// Purges Skia's font cache and resource cache to keep RSS bounded.
/// Call periodically (every 60-120s).
library;

import 'dart:ffi';
import 'dart:io';

DynamicLibrary? _skiaLib;

DynamicLibrary _getSkia() {
  if (_skiaLib != null) return _skiaLib!;
  // Try loading from the bundle's lib directory first.
  final bundleLib = '${Platform.script.resolve('..').toFilePath()}/lib/libskia_dart.so';
  try {
    _skiaLib = DynamicLibrary.open(bundleLib);
    return _skiaLib!;
  } catch (_) {}
  // Fall back to process symbols (for dart run / JIT).
  try {
    _skiaLib = DynamicLibrary.process();
    return _skiaLib!;
  } catch (_) {}
  // Final fallback: dlopen with soname.
  try {
    _skiaLib = DynamicLibrary.open('libskia_dart.so');
    return _skiaLib!;
  } catch (_) {}
  return _skiaLib!; // will throw on next call
}

/// Purges Skia's font cache, resource cache, and all internal caches.
void purgeSkiaCaches() {
  final lib = _getSkia();
  try {
    final purgeAll = lib.lookupFunction<Void Function(), void Function>(
      'sk_graphics_purge_all_caches',
    );
    purgeAll();
  } catch (_) {}
}

/// Returns current Skia font cache usage in bytes, or 0 if unavailable.
int skiaFontCacheUsed() {
  try {
    final lib = _getSkia();
    final getUsed = lib.lookupFunction<Int64 Function(), int Function>(
      'sk_graphics_get_font_cache_used',
    );
    return getUsed();
  } catch (_) {
    return 0;
  }
}

/// Returns Skia font cache limit in bytes, or 0 if unavailable.
int skiaFontCacheLimit() {
  try {
    final lib = _getSkia();
    final getLimit = lib.lookupFunction<Int64 Function(), int Function>(
      'sk_graphics_get_font_cache_limit',
    );
    return getLimit();
  } catch (_) {
    return 0;
  }
}
