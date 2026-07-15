import 'package:window_toolkit/window_toolkit.dart';

import '../metrics.dart';
import '../native/mpris_client.dart';
import 'module.dart';

/// Media player status via MPRIS D-Bus (no `playerctl`).
///
/// Placeholders: {artist} {title} {album} {status} {icon} {player}
///
/// Clicks: left = play/pause, middle/scroll reserved; right unused.
/// Config: max-length (chars), format, format-paused, format-stopped
class MprisModule extends BarModule {
  @override
  String get name => 'mpris';

  Color _color = const Color(180, 180, 180);
  MprisSnapshot _snap = MprisSnapshot.empty;
  void Function(MprisSnapshot)? _listener;
  String _lastOut = '';
  int _maxLength = 40;

  @override
  void init(Map<String, String> config) {
    super.init(config);
    format = resolveFormat(config, '{icon} {artist} - {title}', '');
    interval = parseInt(config, 'interval', 15);
    _maxLength = parseInt(config, 'max-length', 40);
    if (config.containsKey('color')) {
      _color = parseColor(config['color']!);
    }
    _listener = (s) {
      _snap = s;
      _apply();
    };
    MprisClient.instance.addListener(_listener!);
  }

  @override
  void update() {
    MprisClient.instance.refresh();
  }

  void _apply() {
    if (!_snap.hasTrack && !_snap.isPlaying && !_snap.isPaused) {
      final stopped = resolveFormat(config, '', 'stopped');
      output = stopped.isEmpty ? '' : stopped;
      tooltip = '';
      _maybeRepaint();
      return;
    }

    final status = _snap.status.toLowerCase();
    final state = status == 'playing'
        ? ''
        : (status == 'paused' ? 'paused' : status);
    final fmt = resolveFormat(
      config,
      '{icon} {artist} - {title}',
      state,
    );

    final icon = switch (status) {
      'playing' => '',
      'paused' => '',
      _ => '',
    };

    var text = fmt
        .replaceAll('{artist}', _snap.artist)
        .replaceAll('{title}', _snap.title)
        .replaceAll('{album}', _snap.album)
        .replaceAll('{status}', _snap.status)
        .replaceAll('{icon}', icon)
        .replaceAll('{player}', _snap.identity)
        .replaceAll(RegExp(r'\s+-\s+$'), '')
        .replaceAll(RegExp(r'^\s+-\s+'), '')
        .trim();

    if (_maxLength > 0 && text.runes.length > _maxLength) {
      text = '${String.fromCharCodes(text.runes.take(_maxLength - 1))}…';
    }
    output = text;
    tooltip = [
      if (_snap.identity.isNotEmpty) _snap.identity,
      if (_snap.artist.isNotEmpty || _snap.title.isNotEmpty)
        '${_snap.artist}${_snap.artist.isNotEmpty && _snap.title.isNotEmpty ? ' — ' : ''}${_snap.title}',
      _snap.status,
    ].where((s) => s.isNotEmpty).join('\n');
    _maybeRepaint();
  }

  void _maybeRepaint() {
    if (output != _lastOut) {
      _lastOut = output;
      requestRepaint?.call();
    }
  }

  @override
  double measure(Painter painter) {
    if (output.isEmpty) return 0;
    final font = Font.ui(pixelSize: BarMetrics.current.fontSize);
    return painter.measureTextFont(output, font);
  }

  @override
  double draw(Painter painter, double x, double y) {
    if (output.isEmpty) return 0;
    final font = Font.ui(pixelSize: BarMetrics.current.fontSize);
    painter.drawTextFont(output, Offset(x, y), font: font, color: _color);
    return painter.measureTextFont(output, font);
  }

  @override
  void onClick(double x, double y, {int button = 0x110}) {
    if (button == 0x110) {
      MprisClient.instance.playPause();
    } else if (button == 0x112) {
      // Middle
      MprisClient.instance.next();
    }
  }

  @override
  void onScroll(double delta) {
    if (delta < 0) {
      MprisClient.instance.next();
    } else if (delta > 0) {
      MprisClient.instance.previous();
    }
  }
}
