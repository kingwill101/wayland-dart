import 'dart:io';

import 'package:code_assets/code_assets.dart';
import 'package:hooks/hooks.dart';
import 'package:logging/logging.dart';
import 'package:native_toolchain_c/native_toolchain_c.dart';

/// Build [pulse_shim] from `native/pulse_shim.c` as a bundled code asset.
///
/// Linked against system libpulse (`pkg-config --libs libpulse`).
/// Dart bindings: `dart run ffigen --config native/ffigen_pulse.yaml`
void main(List<String> args) async {
  await build(args, (input, output) async {
    if (!input.config.buildCodeAssets) return;

    final logger = Logger('')
      ..level = Level.INFO
      ..onRecord.listen((r) => print(r.message));

    // 1) pulse_shim — libpulse
    final pulseFlags = await _pulsePkgConfigFlags();
    final pulseBuilder = CBuilder.library(
      name: 'pulse_shim',
      assetName: 'src/native/ffigen_pulse.dart',
      sources: ['native/pulse_shim.c'],
      includes: pulseFlags.includes,
      libraries: pulseFlags.libraries,
      libraryDirectories: pulseFlags.libraryDirectories,
      flags: pulseFlags.otherFlags,
    );
    await pulseBuilder.run(input: input, output: output, logger: logger);

    // 2) icon_shim — gtk+-3.0 + librsvg-2.0 + gdk-pixbuf + cairo
    // Native icon theme lookup + SVG raster, replaces manual
    // _parseIndexTheme/_findIconInDirs + rsvg-convert subprocess.
    try {
      final iconFlags = await _pkgConfigFlags(['gtk+-3.0', 'librsvg-2.0']);
      final iconBuilder = CBuilder.library(
        name: 'icon_shim',
        assetName: 'src/native/ffigen_icon.dart',
        sources: ['native/icon_shim.c'],
        includes: iconFlags.includes,
        libraries: iconFlags.libraries,
        libraryDirectories: iconFlags.libraryDirectories,
        flags: iconFlags.otherFlags,
      );
      await iconBuilder.run(input: input, output: output, logger: logger);
    } catch (e) {
      // GTK/librsvg dev headers missing — keeps pulse_shim usable offline
      print('[hook] icon_shim skipped (no gtk/librsvg dev): $e');
    }
  });
}

class _PkgFlags {
  final List<String> includes;
  final List<String> libraries;
  final List<String> libraryDirectories;
  final List<String> otherFlags;
  const _PkgFlags({
    this.includes = const [],
    this.libraries = const ['pulse'],
    this.libraryDirectories = const [],
    this.otherFlags = const [],
  });
}

Future<_PkgFlags> _pkgConfigFlags(List<String> pkgs) async {
  try {
    final r = await Process.run('pkg-config', [
      '--cflags',
      '--libs',
      ...pkgs,
    ]);
    if (r.exitCode != 0) return const _PkgFlags(libraries: []);
    return _parsePkgTokens(r.stdout as String, []);
  } catch (_) {
    return const _PkgFlags(libraries: []);
  }
}

_PkgFlags _parsePkgTokens(String stdout, List<String> baseLibs) {
  final tokens = stdout.trim().split(RegExp(r'\s+'));
  final includes = <String>[];
  final libraries = <String>[...baseLibs];
  final libDirs = <String>[];
  final other = <String>[];
  for (final t in tokens) {
    if (t.startsWith('-I')) includes.add(t.substring(2));
    else if (t.startsWith('-L')) libDirs.add(t.substring(2));
    else if (t.startsWith('-l')) {
      final name = t.substring(2);
      if (!libraries.contains(name)) libraries.add(name);
    } else if (t.isNotEmpty) other.add(t);
  }
  return _PkgFlags(includes: includes, libraries: libraries, libraryDirectories: libDirs, otherFlags: other);
}

Future<_PkgFlags> _pulsePkgConfigFlags() async {
  try {
    final r = await Process.run('pkg-config', [
      '--cflags',
      '--libs',
      'libpulse',
    ]);
    if (r.exitCode != 0) return const _PkgFlags();
    final tokens = (r.stdout as String).trim().split(RegExp(r'\s+'));
    final includes = <String>[];
    final libraries = <String>['pulse'];
    final libDirs = <String>[];
    final other = <String>[];
    for (final t in tokens) {
      if (t.startsWith('-I')) {
        includes.add(t.substring(2));
      } else if (t.startsWith('-L')) {
        libDirs.add(t.substring(2));
      } else if (t.startsWith('-l')) {
        final name = t.substring(2);
        if (!libraries.contains(name)) libraries.add(name);
      } else if (t.isNotEmpty) {
        other.add(t);
      }
    }
    return _PkgFlags(
      includes: includes,
      libraries: libraries,
      libraryDirectories: libDirs,
      otherFlags: other,
    );
  } catch (_) {
    return const _PkgFlags();
  }
}
