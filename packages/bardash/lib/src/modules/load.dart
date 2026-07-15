import 'dart:io';

import 'package:window_toolkit/window_toolkit.dart';

import 'module.dart';

class LoadModule extends BarModule {
  @override
  String get name => 'load';

  String _format = 'Load {avg1}';
  // ignore: unused_field - used by bar scheduler
  int _interval = 5;
  String _display = '';
  Color _color = const Color(0xff, 0xff, 0xff);

  int _cpuCount = 4;

  @override
  void init(Map<String, String> config) {
    if (config.containsKey('format')) _format = config['format']!;
    if (config.containsKey('interval')) {
      _interval = int.tryParse(config['interval']!) ?? 5;
    }
    _cpuCount = _readCpuCount();
  }

  @override
  void update() {
    try {
      final line = File('/proc/loadavg').readAsStringSync().trim();
      final parts = line.split(RegExp(r'\s+'));
      if (parts.length < 3) {
        _display = 'ERR';
        return;
      }

      final avg1 = double.tryParse(parts[0]);
      final avg5 = double.tryParse(parts[1]);
      final avg15 = double.tryParse(parts[2]);

      if (avg1 == null || avg5 == null || avg15 == null) {
        _display = 'ERR';
        return;
      }

      if (avg1 > _cpuCount) {
        _color = const Color(0xff, 0x33, 0x33);
      } else {
        _color = const Color(0xff, 0xff, 0xff);
      }

      _display = _format
          .replaceAll('{avg1}', avg1.toStringAsFixed(2))
          .replaceAll('{avg5}', avg5.toStringAsFixed(2))
          .replaceAll('{avg15}', avg15.toStringAsFixed(2));
    } catch (_) {
      _display = 'ERR';
    }
  }

  int _readCpuCount() {
    try {
      final data = File('/proc/cpuinfo').readAsStringSync();
      int count = 0;
      for (final line in data.split('\n')) {
        if (line.startsWith('processor')) {
          count++;
        }
      }
      return count > 0 ? count : 4;
    } catch (_) {
      return 4;
    }
  }

  @override
  double draw(Painter painter, double x, double y) {
    painter.drawText(_display, Offset(x, y), color: _color);
    return painter.measureText(_display).width;
  }
}
