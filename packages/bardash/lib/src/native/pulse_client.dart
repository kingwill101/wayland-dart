/// PulseAudio / PipeWire-Pulse volume via ffigen-generated [PulseShimBindings].
///
/// Percentages match `pactl` / waybar (`100 * avg / PA_VOLUME_NORM`).
///
/// Native library is built by `hook/build.dart` (native assets). Bindings:
/// ```sh
/// dart run ffigen --config native/ffigen_pulse.yaml
/// ```
library;

import 'dart:async';
import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';

import 'ffigen_pulse.dart';

/// Snapshot of default sink + source volume.
class PulseSnapshot {
  final int sinkPercent;
  final bool sinkMuted;
  final int sourcePercent;
  final bool sourceMuted;

  const PulseSnapshot({
    required this.sinkPercent,
    required this.sinkMuted,
    required this.sourcePercent,
    required this.sourceMuted,
  });

  static const zero = PulseSnapshot(
    sinkPercent: 0,
    sinkMuted: false,
    sourcePercent: 0,
    sourceMuted: false,
  );

  @override
  bool operator ==(Object other) =>
      other is PulseSnapshot &&
      other.sinkPercent == sinkPercent &&
      other.sinkMuted == sinkMuted &&
      other.sourcePercent == sourcePercent &&
      other.sourceMuted == sourceMuted;

  @override
  int get hashCode =>
      Object.hash(sinkPercent, sinkMuted, sourcePercent, sourceMuted);
}

/// Process-wide Pulse client (threaded mainloop inside pulse_shim).
class PulseClient {
  PulseClient._();
  static final PulseClient instance = PulseClient._();

  PulseShimBindings? _b;
  bool _started = false;
  Timer? _poll;
  final _listeners = <void Function(PulseSnapshot)>[];
  PulseSnapshot _last = PulseSnapshot.zero;

  PulseSnapshot get last => _last;
  bool get available => _b != null && _started;

  void addListener(void Function(PulseSnapshot) fn) {
    _listeners.add(fn);
    if (!_started) {
      unawaited(_ensureStarted());
    } else {
      fn(_last);
    }
  }

  void removeListener(void Function(PulseSnapshot) fn) {
    _listeners.remove(fn);
  }

  Future<void> _ensureStarted() async {
    if (_started) return;
    final dylib = _openLibrary();
    if (dylib == null) {
      _started = true; // don't spin forever
      return;
    }
    _b = PulseShimBindings(dylib);
    final rc = _b!.pulse_shim_start();
    if (rc != 0) {
      stderr.writeln('[bardash] pulse_shim_start failed ($rc)');
      _started = true;
      return;
    }
    _started = true;
    await Future<void>.delayed(const Duration(milliseconds: 80));
    _pull(force: true);
    _poll = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (_b!.pulse_shim_take_dirty() != 0) {
        _pull(force: true);
      }
    });
  }

  /// Prefer native-assets bundle, then common dev paths.
  DynamicLibrary? _openLibrary() {
    final candidates = <String>[
      // After `dart run` / native assets hook:
      'libpulse_shim.so',
      // Dev tree (packages/bardash)
      '${Directory.current.path}/native/libpulse_shim.so',
      '${Directory.current.path}/.dart_tool/lib/libpulse_shim.so',
      // Monorepo root
      '${Directory.current.path}/packages/bardash/native/libpulse_shim.so',
    ];
    for (final p in candidates) {
      try {
        if (p != 'libpulse_shim.so' && !File(p).existsSync()) continue;
        final lib = DynamicLibrary.open(p);
        stderr.writeln('[bardash] pulse: loaded $p (ffigen PulseShimBindings)');
        return lib;
      } catch (_) {}
    }
    stderr.writeln(
      '[bardash] libpulse_shim.so not found. '
      'Native assets hook should build it on `dart run`; or: '
      'cd native && gcc -shared -fPIC -o libpulse_shim.so pulse_shim.c '
      '\$(pkg-config --cflags --libs libpulse)',
    );
    return null;
  }

  void _pull({bool force = false}) {
    final b = _b;
    if (b == null) return;
    final sp = calloc<Int>();
    final sm = calloc<Int>();
    final cp = calloc<Int>();
    final cm = calloc<Int>();
    try {
      if (b.pulse_shim_get(sp, sm, cp, cm) == 0) return;
      final next = PulseSnapshot(
        sinkPercent: sp.value,
        sinkMuted: sm.value != 0,
        sourcePercent: cp.value,
        sourceMuted: cm.value != 0,
      );
      if (!force && next == _last) return;
      _last = next;
      for (final l in List.of(_listeners)) {
        l(_last);
      }
    } finally {
      calloc.free(sp);
      calloc.free(sm);
      calloc.free(cp);
      calloc.free(cm);
    }
  }

  bool stepVolume(int deltaPercent) {
    final b = _b;
    if (!available || b == null) return false;
    if (b.pulse_shim_sink_volume_step(deltaPercent) != 0) return false;
    _pull(force: true);
    return true;
  }

  bool toggleMute() {
    final b = _b;
    if (!available || b == null) return false;
    if (b.pulse_shim_toggle_mute() != 0) return false;
    _pull(force: true);
    return true;
  }

  bool stepSourceVolume(int deltaPercent) {
    final b = _b;
    if (!available || b == null) return false;
    if (b.pulse_shim_source_volume_step(deltaPercent) != 0) return false;
    _pull(force: true);
    return true;
  }

  bool toggleSourceMute() {
    final b = _b;
    if (!available || b == null) return false;
    if (b.pulse_shim_toggle_source_mute() != 0) return false;
    _pull(force: true);
    return true;
  }

  void refresh() {
    if (!available) return;
    _b?.pulse_shim_refresh();
    _pull(force: true);
  }

  Future<void> dispose() async {
    _poll?.cancel();
    _poll = null;
    if (_started) {
      _b?.pulse_shim_stop();
    }
    _started = false;
    _b = null;
  }
}
