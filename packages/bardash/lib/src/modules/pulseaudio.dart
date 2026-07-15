import 'dart:io';

import 'package:window_toolkit/window_toolkit.dart';

import 'module.dart';

class PulseaudioModule extends BarModule {
  @override
  String get name => 'pulseaudio';

  int _volume = 0;
  bool _muted = false;

  @override
  void init(Map<String, String> config) {
    super.init(config);
    format = resolveFormat(config, '{volume}% {icon}', '');
    interval = parseInt(config, 'interval', 2);
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
}
