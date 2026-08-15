import 'dart:io';

import 'module.dart';

class LoadModule extends BarModule {
  @override
  String get name => 'load';

  String _format = 'Load {avg1}';
  // ignore: unused_field - used by bar scheduler
  int _interval = 5;
  String _display = '';

  @override
  void init(Map<String, String> config) {
    super.init(config);
    if (config.containsKey('format')) _format = config['format']!;
    if (config.containsKey('interval')) {
      _interval = int.tryParse(config['interval']!) ?? 5;
    }
  }

  @override
  void update() {
    try {
      final line = File('/proc/loadavg').readAsStringSync().trim();
      final parts = line.split(RegExp(r'\s+'));
      if (parts.length < 3) {
        _display = 'ERR';
        output = _display;
        return;
      }

      final avg1 = double.tryParse(parts[0]);
      final avg5 = double.tryParse(parts[1]);
      final avg15 = double.tryParse(parts[2]);

      if (avg1 == null || avg5 == null || avg15 == null) {
        _display = 'ERR';
        output = _display;
        return;
      }

      _display = _format
          .replaceAll('{avg1}', avg1.toStringAsFixed(2))
          .replaceAll('{avg5}', avg5.toStringAsFixed(2))
          .replaceAll('{avg15}', avg15.toStringAsFixed(2));
      output = _display;
    } catch (_) {
      _display = 'ERR';
      output = _display;
    }
  }
}
