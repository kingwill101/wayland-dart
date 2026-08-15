import 'dart:io';

import 'package:window_toolkit/window_toolkit.dart';

import '../audio_popup.dart';
import '../bar_text.dart';
import '../command.dart';
import '../native/pulse_client.dart';
import '../native/mpris_client.dart';
import 'module.dart';

/// A click-to-open audio panel module.
///
/// Draws the current volume (icon + percent). A left
/// click toggles the [AudioPopupOverlay] master-volume panel, where the
/// slider drags [PulseClient] live; right-click uses `on-click-right`
/// (config) as usual.
///
/// Config keys:
///   format       – text format (default: "{icon} {volume}%{media}")
///   media-format – media segment (default: " · {artist} — {title}")
///                   Placeholders: {media}, {artist}, {title}, {album},
///                   {player}, {status}, {media-icon}
///   interval     – fallback poll seconds when the native shim is absent (2)
///   scroll-step  – volume delta per wheel tick (default: 5)
///   mixer-command – external mixer to launch from the popup's Mixer button
///                  (default: auto-detect pavucontrol / pwvucontrol / helvum)
class AudioModule extends BarModule {
  final bool mediaOnly;

  AudioModule({this.mediaOnly = false});

  @override
  String get name => 'audio';

  @override
  bool get showsGraphics => false;

  @override
  bool get needsPopupOverlay => true;

  WaylandConnection? _connection;
  int _parentWidth = 1920;
  int _parentHeight = 30;
  bool _openUpward = true;
  String _mixerCommand = '';
  int _scrollStep = 5;

  int _volume = 0;
  bool _muted = false;
  int _mediaMaxLength = 32;
  MprisSnapshot _media = MprisSnapshot.empty;
  String _mediaFormat = ' · {artist} — {title}';

  /// Called by the bar once the layer surface exists, so the popup can
  /// create its own overlay surfaces on the same connection.
  @override
  void attachPopupOverlay(
    WaylandConnection connection, {
    int parentWidth = 1920,
    int parentHeight = 30,
    bool openUpward = true,
  }) {
    _connection = connection;
    _parentWidth = parentWidth;
    _parentHeight = parentHeight;
    _openUpward = openUpward;
  }

  String get _levelIcon => _muted
      ? '\u{f026}' // muted
      : getIcon(_volume, ['\u{f025}', '\u{f027}', '\u{f028}']);

  @override
  void init(Map<String, String> config) {
    super.init(config);
    format = resolveFormat(
      config,
      mediaOnly ? '{media-icon} {media}' : '{icon} {volume}%',
      '',
    );
    interval = parseInt(config, 'interval', 2);
    _mixerCommand = config['mixer-command'] ?? '';
    _scrollStep = parseInt(config, 'scroll-step', 5).clamp(1, 25);
    _mediaMaxLength = parseInt(config, 'media-max-length', 32).clamp(0, 160);
    _mediaFormat = config['media-format'] ?? _mediaFormat;

    // Live updates from the native pulse shim when available.
    PulseClient.instance.addListener((s) {
      _volume = s.sinkPercent;
      _muted = s.sinkMuted;
      _compose();
      requestRepaint?.call();
    });

    // MPRIS is session-D-Bus based and event-driven; no playerctl polling.
    MprisClient.instance.addListener((s) {
      _media = s;
      _compose();
      requestRepaint?.call();
    });
  }

  void _compose() {
    var mediaText = '';
    if (_media.hasTrack) {
      final artistTitle = [
        _media.artist,
        _media.title,
      ].where((part) => part.isNotEmpty).join(' — ');
      mediaText = _mediaFormat
          .replaceAll('{artist}', _media.artist)
          .replaceAll('{title}', _media.title)
          .replaceAll('{album}', _media.album)
          .replaceAll('{player}', _media.identity)
          .replaceAll('{status}', _media.status)
          .replaceAll('{media-icon}', _media.isPlaying ? '' : '')
          .replaceAll('{media}', artistTitle)
          .replaceAll(RegExp(r'\s+—\s*$'), '')
          .trim();
      if (_mediaMaxLength > 0 && mediaText.runes.length > _mediaMaxLength) {
        mediaText =
            '${String.fromCharCodes(mediaText.runes.take(_mediaMaxLength - 1))}…';
      }
    }
    output = format
        .replaceAll('{icon}', _levelIcon)
        .replaceAll('{volume}', '$_volume')
        .replaceAll('{muted}', _muted ? 'yes' : 'no')
        .replaceAll('{media}', mediaText)
        .replaceAll('{artist}', _media.artist)
        .replaceAll('{title}', _media.title)
        .replaceAll('{album}', _media.album)
        .replaceAll('{player}', _media.identity)
        .replaceAll('{status}', _media.status)
        .replaceAll('{media-icon}', _media.isPlaying ? '' : '')
        .replaceAll(RegExp(r'\s{2,}'), ' ')
        .trim();
    tooltip = resolveTooltip(
      _media.hasTrack
          ? '${_media.identity}\n${_media.artist} — ${_media.title}\n${_media.status}'
          : 'Volume $_volume%${_muted ? ' (muted)' : ''}',
      {
        'volume': '$_volume',
        'muted': _muted ? 'yes' : 'no',
        'artist': _media.artist,
        'title': _media.title,
        'album': _media.album,
        'player': _media.identity,
        'status': _media.status,
      },
    );
  }

  @override
  void update() {
    if (PulseClient.instance.available) {
      final s = PulseClient.instance.last;
      _volume = s.sinkPercent;
      _muted = s.sinkMuted;
      _compose();
      return;
    }
    // Fallback when the native shim is unavailable: poll pactl / amixer.
    try {
      var result = _runPactl();
      if (result == null) result = _runAmixer();
      if (result == null) {
        output = 'ERR';
        return;
      }
      _volume = result.$1;
      _muted = result.$2;
      _compose();
    } catch (_) {
      output = 'ERR';
    }
  }

  (int, bool)? _runPactl() {
    final volResult = Process.runSync('pactl', [
      'get-sink-volume',
      '@DEFAULT_SINK@',
    ], runInShell: true);
    if (volResult.exitCode != 0) return null;
    final volOut = volResult.stdout as String;
    final volMatch = RegExp(r'(\d+)%').firstMatch(volOut);
    if (volMatch == null) return null;
    final volume = int.parse(volMatch.group(1)!);

    final muteResult = Process.runSync('pactl', [
      'get-sink-mute',
      '@DEFAULT_SINK@',
    ], runInShell: true);
    final muted =
        muteResult.exitCode == 0 &&
        (muteResult.stdout as String).contains('Mute: yes');
    return (volume, muted);
  }

  (int, bool)? _runAmixer() {
    final result = Process.runSync('amixer', [
      'get',
      'Master',
    ], runInShell: true);
    if (result.exitCode != 0) return null;
    final out = result.stdout as String;
    final volMatch = RegExp(r'\[(\d+)%\]').firstMatch(out);
    if (volMatch == null) return null;
    final volume = int.parse(volMatch.group(1)!);
    final muted = out.contains('[off]');
    return (volume, muted);
  }

  @override
  double measure(Painter painter) {
    final textWidth = output.isEmpty
        ? 0
        : painter.measureTextFont(output, BarText.fontFor(output));
    return textWidth.toDouble();
  }

  @override
  double draw(Painter painter, double x, double y) {
    final text = output;
    final font = BarText.fontFor(text);
    final color = cssForeground ?? const Color(0xc8, 0xc8, 0xc8);
    painter.drawTextFont(text, Offset(x, y), font: font, color: color);
    return painter.measureTextFont(text, font);
  }

  @override
  bool get hasClick => true;

  /// Wheel over the module steps output volume (±[scroll-step]%), using the
  /// native shim, with a pactl fallback. Custom on-scroll-* commands win.
  @override
  void onScroll(double delta) {
    if (delta == 0) return;
    if (onScrollUpCmd.isNotEmpty && delta < 0) {
      runBarCommand(onScrollUpCmd);
      return;
    }
    if (onScrollDownCmd.isNotEmpty && delta > 0) {
      runBarCommand(onScrollDownCmd);
      return;
    }
    final up = delta < 0;
    final deltaVol = up ? _scrollStep : -_scrollStep;
    if (PulseClient.instance.available) {
      PulseClient.instance.stepVolume(deltaVol);
    } else {
      Process.run('pactl', [
        'set-sink-volume',
        '@DEFAULT_SINK@',
        '${up ? '+' : '-'}$_scrollStep%',
      ], runInShell: false);
      Process.run('pactl', [
        'set-sink-mute',
        '@DEFAULT_SINK@',
        '0',
      ], runInShell: false);
    }
    update();
    requestRepaint?.call();
  }

  @override
  void onClick(double x, double y, {int button = 0x110}) {
    if (button == 0x112) {
      MprisClient.instance.playPause();
      return;
    }
    if (button == 0x111) return; // right-click handled by bar (on-click-right)
    final connection = _connection;
    if (connection == null) {
      // No layer connection (headless / early): fallback to pactl mute toggle.
      final arg = _muted ? '0' : '1';
      Process.runSync('pactl', [
        'set-sink-mute',
        '@DEFAULT_SINK@',
        arg,
      ], runInShell: true);
      update();
      return;
    }
    if (AudioPopupController.isOpen) {
      AudioPopupController.close();
    } else {
      AudioPopupController.open(
        connection: connection,
        anchorX: hoverX.round(),
        parentWidth: _parentWidth,
        parentHeight: _parentHeight,
        openUpward: _openUpward,
        mixerCommand: _mixerCommand.isEmpty ? null : _mixerCommand,
      );
    }
  }
}
