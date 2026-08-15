import 'dart:io';

import 'module.dart';

class KeyboardStateModule extends BarModule {
  @override
  String get name => 'keyboard-state';

  bool _showCapslock = true;
  bool _showNumlock = false;
  bool _capsOn = false;
  bool _numOn = false;

  @override
  void init(Map<String, String> config) {
    super.init(config);
    format = resolveFormat(config, '{name}', '');
    interval = parseInt(config, 'interval', 2);
    if (config.containsKey('capslock')) {
      _showCapslock = config['capslock']!.toLowerCase() == 'true';
    }
    if (config.containsKey('numlock')) {
      _showNumlock = config['numlock']!.toLowerCase() == 'true';
    }
  }

  @override
  void update() {
    _capsOn = _readBrightness('capslock');
    _numOn = _readBrightness('numlock');

    final parts = <String>[];
    if (_showCapslock && _capsOn) {
      parts.add(_resolveFormat('CAPS'));
    }
    if (_showNumlock && _numOn) {
      parts.add(_resolveFormat('NUM'));
    }
    output = parts.join(' ');
  }

  String _resolveFormat(String name) {
    return format.replaceAll('{name}', name).replaceAll('{icon}', '\u{25C9}');
  }

  bool _readBrightness(String type) {
    try {
      final dir = Directory('/sys/class/leds');
      if (!dir.existsSync()) return false;

      for (final entry in dir.listSync()) {
        final name = entry.path.split('/').last;
        if (name.startsWith('input') && name.endsWith('::$type')) {
          final brightnessFile = File('${entry.path}/brightness');
          if (!brightnessFile.existsSync()) continue;
          final value = brightnessFile.readAsStringSync().trim();
          return value == '1';
        }
      }
    } catch (_) {}
    return false;
  }
}
