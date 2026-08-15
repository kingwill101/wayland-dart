import 'dart:io';

import 'package:window_toolkit/window_toolkit.dart';

import '../command.dart';
import 'module.dart';

class PulseaudioModule extends BarModule {
  @override
  String get name => 'pulseaudio';

  int _volume = 0;
  bool _muted = false;
  int _scrollStep = 5;

  @override
  void init(Map<String, String> config) {
    super.init(config);
    format = resolveFormat(config, '{volume}% {icon}', '');
    interval = parseInt(config, 'interval', 2);
    _scrollStep = parseInt(config, 'scroll-step', 5).clamp(1, 25);
  }

  @override
  void update() {
    try {
      var result = _runPactl();
      if (result == null) {
        result = _runAmixer();
      }
      if (result == null) {
        output = 'ERR';
        return;
      }
      _volume = result.$1;
      _muted = result.$2;

      final icon = _muted
          ? '󰝟'
          : getIcon(_volume, ['', '', '']);
      output = format
          .replaceAll('{volume}', '$_volume')
          .replaceAll('{icon}', icon)
          .replaceAll('{muted}', _muted ? 'yes' : 'no');
    } catch (_) {
      output = 'ERR';
    }
  }

  (int, bool)? _runPactl() {
    final volResult = Process.runSync(
        'pactl', ['get-sink-volume', '@DEFAULT_SINK@'],
        runInShell: true);
    if (volResult.exitCode != 0) return null;
    final volOut = volResult.stdout as String;
    final volMatch = RegExp(r'(\d+)%').firstMatch(volOut);
    if (volMatch == null) return null;
    final volume = int.parse(volMatch.group(1)!);

    final muteResult = Process.runSync(
        'pactl', ['get-sink-mute', '@DEFAULT_SINK@'],
        runInShell: true);
    final muted = muteResult.exitCode == 0 &&
        (muteResult.stdout as String).contains('Mute: yes');

    return (volume, muted);
  }

  (int, bool)? _runAmixer() {
    final result = Process.runSync('amixer', ['get', 'Master'],
        runInShell: true);
    if (result.exitCode != 0) return null;
    final out = result.stdout as String;
    final volMatch = RegExp(r'\[(\d+)%\]').firstMatch(out);
    if (volMatch == null) return null;
    final volume = int.parse(volMatch.group(1)!);
    final muted = out.contains('[off]');
    return (volume, muted);
  }

  @override
  double draw(Painter painter, double x, double y) {
    painter.drawText(output, Offset(x, y));
    return painter.measureText(output).width;
  }

  /// Wheel steps the default sink volume (±[scroll-step]%, default 5).
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
    final step = delta < 0 ? '+$_scrollStep%' : '-$_scrollStep%';
    Process.run('pactl', ['set-sink-volume', '@DEFAULT_SINK@', step],
        runInShell: false);
    Process.run('pactl', ['set-sink-mute', '@DEFAULT_SINK@', '0'],
        runInShell: false);
    update();
  }
}
