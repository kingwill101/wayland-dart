import 'dart:io';

import 'package:window_toolkit/window_toolkit.dart';

import 'module.dart';

class VolumeModule extends BarModule {
  @override
  String get name => 'volume';

  Color _color = const Color(180, 180, 180);
  int _volume = 0;
  bool _muted = false;

  @override
  void init(Map<String, String> config) {
    super.init(config);
    format = resolveFormat(config, 'Vol {volume}%', '');
    interval = parseInt(config, 'interval', 2);
    if (config.containsKey('color')) {
      _color = parseColor(config['color']!);
    }
  }

  @override
  void update() {
    try {
      final result = Process.runSync('amixer', ['get', 'Master'],
          runInShell: true);
      if (result.exitCode != 0) {
        output = 'Vol ERR';
        return;
      }
      final out = result.stdout as String;
      final volMatch = RegExp(r'\[(\d+)%\]').firstMatch(out);
      if (volMatch == null) {
        output = 'Vol N/A';
        return;
      }
      _volume = int.parse(volMatch.group(1)!);
      _muted = out.contains('[off]');

      final icon = _muted
          ? '󰝟'
          : getIcon(_volume, ['', '', '']);
      output = format
          .replaceAll('{volume}', '$_volume')
          .replaceAll('{icon}', icon);
    } catch (_) {
      output = 'Vol ERR';
    }
  }

  @override
  double draw(Painter painter, double x, double y) {
    final size = painter.measureText(output, size: 14);
    painter.drawText(output, Offset(x, y), color: _color, size: 14);
    return size.width;
  }
}
