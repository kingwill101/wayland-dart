/// Live-reload helper — mirrors waybar's file-watch on `style.css`.
///
/// Usage:
/// ```dart
/// final provider = CssProvider()..loadFromPath('style.css');
/// StyleContext.addProviderForScreen(provider);
/// final reloader = CssReloadHelper(provider, path: 'style.css');
/// reloader.start(); // watches parent dir, reloads on modify
/// // ...
/// reloader.dispose();
/// ```
library;

import 'dart:async';
import 'dart:io';

import 'css_provider.dart';

typedef CssReloadCallback = void Function(bool success);

class CssReloadHelper {
  final CssProvider provider;
  final String path;
  final bool isScss;
  final CssReloadCallback? onReload;
  StreamSubscription<FileSystemEvent>? _sub;

  CssReloadHelper(
    this.provider, {
    required this.path,
    this.isScss = false,
    this.onReload,
  });

  Future<void> start() async {
    final file = File(path);
    final dir = file.parent;
    if (!dir.existsSync()) return;
    _sub = dir.watch(events: FileSystemEvent.modify).listen((event) {
      if (event.path == file.path) {
        final ok = provider.loadFromPath(path, isScss: isScss);
        onReload?.call(ok);
        // Trigger a global repaint so widgets re-query StyleContext.
        // The owning widget host binds repaint callbacks to each widget.
        try {
          // ignore: avoid_dynamic_calls
          final dynamic w = provider;
          // No direct repaint hook here — caller can wire onReload to setState.
          w.toString();
        } catch (_) {}
      }
    });
  }

  Future<void> dispose() async {
    await _sub?.cancel();
    _sub = null;
  }
}
