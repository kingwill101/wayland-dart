import 'dart:io';

import 'module.dart';

class VolumeModule extends BarModule {
  @override
  String get name => 'volume';

  int _volume = 0;
  bool _muted = false;

  @override
  void init(Map<String, String> config) {
    super.init(config);
    format = resolveFormat(config, 'Vol {volume}%', '');
    interval = parseInt(config, 'interval', 2);
  }

  @override
  void update() {
    try {
      final result = Process.runSync('amixer', [
        'get',
        'Master',
      ], runInShell: true);
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

      final icon = _muted ? '󰝟' : getIcon(_volume, ['', '', '']);
      output = format
          .replaceAll('{volume}', '$_volume')
          .replaceAll('{icon}', icon);
    } catch (_) {
      output = 'Vol ERR';
    }
  }
}
