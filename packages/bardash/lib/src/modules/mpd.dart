import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';

import '../native/ffigen_mpd.dart';
import 'module.dart';

/// Music Player Daemon module using ffigen-generated libmpdclient bindings.
///
/// Connects to MPD via direct C function calls — no subprocess. Uses
/// the ffigen-generated [MpdBindings] class loaded from
/// `libmpdclient.so.2`.
///
/// Format placeholders:
///   {artist}     – current song artist
///   {title}      – current song title
///   {album}      – current song album
///   {elapsed}    – elapsed time formatted MM:SS
///   {total}      – total duration formatted MM:SS
///   {state}      – "play", "pause", or "stop"
///   {volume}     – MPD volume (0–100)
///   {icon}       – ▶ / ⏸ / ⏹
///
/// Config keys:
///   host             – MPD host (default: "127.0.0.1")
///   port             – MPD port (default: 6600)
///   format           – display format (default: "{artist} - {title}")
///   format-paused    – format when paused
///   format-stopped   – format when stopped (empty = hidden)
///   interval         – refresh in seconds (default: 2)
///   max-length       – truncate output to N chars (default: 0 = no limit)
///   on-click         – command on click
class MpdModule extends BarModule {
  @override
  String get name => 'mpd';

  String _host = '127.0.0.1';
  int _port = 6600;
  int _maxLength = 0;

  MpdBindings? _lib;
  Pointer<mpd_connection>? _conn;
  bool _useMpc = false;
  bool? _mpcAvailable;
  bool _updating = false;
  String _lastOutput = '';

  @override
  void init(Map<String, String> config) {
    super.init(config);
    format = resolveFormat(config, '{artist} - {title}', '');
    interval = parseInt(config, 'interval', 3);
    _maxLength = parseInt(config, 'max-length', 0);
    if (config.containsKey('host')) _host = config['host']!;
    if (config.containsKey('port')) {
      _port = int.tryParse(config['port']!) ?? 6600;
    }

    try {
      final dylib = DynamicLibrary.open('libmpdclient.so.2');
      _lib = MpdBindings(dylib);
    } catch (_) {
      _lib = null;
      _useMpc = true;
    }
  }

  // ── Connect / disconnect ───────────────────────────────────────────

  bool _connect() {
    if (_conn != null) return true;
    if (_lib == null) return false;

    final hostPtr = _host.toNativeUtf8();
    try {
      _conn = _lib!.mpd_connection_new(hostPtr.cast(), _port, 3000);
      if (_conn == nullptr ||
          _lib!.mpd_connection_get_error(_conn!) !=
              mpd_error.MPD_ERROR_SUCCESS) {
        _disconnect();
        return false;
      }
      return true;
    } finally {
      calloc.free(hostPtr);
    }
  }

  void _disconnect() {
    if (_conn != null) {
      _lib!.mpd_connection_free(_conn!);
      _conn = null;
    }
  }

  // ── Update (FFI) ───────────────────────────────────────────────────

  void _updateViaFfi() {
    if (!_connect()) {
      // Fall back to CLI when MPD server isn't reachable
      _useMpc = true;
      return;
    }

    // Get status
    final status = _lib!.mpd_run_status(_conn!);
    if (status == nullptr) {
      _disconnect();
      output = 'N/A';
      return;
    }

    final state = _lib!.mpd_status_get_state(status);
    final volume = _lib!.mpd_status_get_volume(status);
    final elapsed = _lib!.mpd_status_get_elapsed_time(status);
    final total = _lib!.mpd_status_get_total_time(status);
    _lib!.mpd_status_free(status);

    // Get current song
    String artist = '', title = '', album = '';
    final song = _lib!.mpd_run_current_song(_conn!);
    if (song != nullptr) {
      artist = _readTag(song, mpd_tag_type.MPD_TAG_ARTIST) ?? '';
      title = _readTag(song, mpd_tag_type.MPD_TAG_TITLE) ?? '';
      album = _readTag(song, mpd_tag_type.MPD_TAG_ALBUM) ?? '';
      _lib!.mpd_song_free(song);
    }

    final stateStr = state == mpd_state.MPD_STATE_PLAY
        ? 'play'
        : state == mpd_state.MPD_STATE_PAUSE
        ? 'pause'
        : 'stop';

    _buildOutput(
      state: stateStr,
      volumeMpd: volume,
      elapsed: elapsed,
      total: total,
      artist: artist,
      title: title,
      album: album,
    );
  }

  String? _readTag(Pointer<mpd_song> song, mpd_tag_type tag) {
    final ptr = _lib!.mpd_song_get_tag(song, tag, 0);
    if (ptr == nullptr) return null;
    return ptr.cast<Utf8>().toDartString();
  }

  // ── CLI fallback (async — never runSync on the timer path) ─────────

  Future<void> _updateViaMpc() async {
    try {
      if (_mpcAvailable == null) {
        final which = await Process.run('which', ['mpc'], runInShell: false);
        _mpcAvailable = which.exitCode == 0;
      }
      if (_mpcAvailable != true) {
        output = 'no mpc';
        return;
      }

      final r = await Process.run('mpc', [
        'status',
        '%artist%||%title%||%album%||%state%||%volume%',
      ], runInShell: false);
      if (r.exitCode != 0) {
        output = 'mpd N/A';
        return;
      }

      final parts = (r.stdout as String).trim().split('\n')[0].split('||');
      if (parts.length >= 5) {
        _buildOutput(
          artist: parts[0].trim(),
          title: parts[1].trim(),
          album: parts[2].trim(),
          state: parts[3].trim().toLowerCase(),
          volumeMpd: int.tryParse(parts[4].replaceAll('%', '').trim()) ?? 0,
          elapsed: 0,
          total: 0,
        );
      } else {
        output = '';
      }
    } catch (_) {
      output = 'mpd N/A';
    }
  }

  // ── Update dispatch ────────────────────────────────────────────────

  @override
  void update() {
    if (_updating) return;
    _updating = true;
    Future<void>(() async {
      if (_lib != null && !_useMpc) {
        _updateViaFfi();
        // FFI path may flip to CLI if the daemon is down.
        if (_useMpc) await _updateViaMpc();
      } else {
        await _updateViaMpc();
      }
      if (output != _lastOutput) {
        _lastOutput = output;
        requestRepaint?.call();
      }
    }).whenComplete(() {
      _updating = false;
    });
  }

  // ── Output builder ─────────────────────────────────────────────────

  void _buildOutput({
    required String state,
    required int volumeMpd,
    required int elapsed,
    required int total,
    required String artist,
    required String title,
    required String album,
  }) {
    String fmt;
    if (state == 'play') {
      fmt = resolveFormat({'format': format}, format, '');
    } else if (state == 'pause') {
      fmt = resolveFormat(
        {'format': format, 'format-paused': format},
        format,
        'paused',
      );
    } else {
      fmt = resolveFormat(
        {'format': format, 'format-stopped': ''},
        format,
        'stopped',
      );
    }
    if (state == 'stop' && fmt == format) {
      output = '';
      return;
    }

    final icon = state == 'play'
        ? '\u25B6'
        : state == 'pause'
        ? '\u23F8'
        : '\u23F9';
    var result = fmt
        .replaceAll('{artist}', artist)
        .replaceAll('{title}', title)
        .replaceAll('{album}', album)
        .replaceAll('{state}', state)
        .replaceAll('{volume}', volumeMpd.toString())
        .replaceAll('{icon}', icon)
        .replaceAll('{elapsed}', _fmtDur(elapsed))
        .replaceAll('{total}', _fmtDur(total));
    if (_maxLength > 0 && result.length > _maxLength) {
      result = '${result.substring(0, _maxLength)}\u2026';
    }
    output = result;
  }

  String _fmtDur(int s) =>
      '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';
}
