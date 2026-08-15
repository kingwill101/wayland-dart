import 'dart:io';

import 'module.dart';

class BacklightModule extends BarModule {
  @override
  String get name => 'backlight';

  String _format = '\u2600 {percent}%';
  int _interval = 3;
  String _display = '';

  @override
  void init(Map<String, String> config) {
    super.init(config);
    _format = config['format'] ?? _format;
    _interval = int.tryParse(config['interval'] ?? '') ?? _interval;
  }

  @override
  void update() {
    try {
      final backlightDir = Directory('/sys/class/backlight');
      final entries = backlightDir.listSync();
      if (entries.isEmpty) {
        _display = 'N/A';
        output = _display;
        return;
      }
      final dir = entries.first.path;
      final brightness = int.tryParse(
        File('$dir/brightness').readAsStringSync().trim(),
      );
      final maxBrightness = int.tryParse(
        File('$dir/max_brightness').readAsStringSync().trim(),
      );

      if (brightness == null || maxBrightness == null || maxBrightness == 0) {
        _display = 'N/A';
        output = _display;
        return;
      }

      final percent = brightness / maxBrightness * 100;
      _display = _format.replaceAll('{percent}', percent.toStringAsFixed(0));
      output = _display;
    } catch (_) {
      _display = 'N/A';
      output = _display;
    }
  }
}
