import 'dart:io';

import 'module.dart';

class TemperatureModule extends BarModule {
  @override
  String get name => 'temperature';

  String _format = '{temp}°C';
  // ignore: unused_field - used by bar scheduler
  int _interval = 5;
  String? _thermalZone;
  String _display = '';

  @override
  void init(Map<String, String> config) {
    super.init(config);
    if (config.containsKey('format')) _format = config['format']!;
    if (config.containsKey('interval')) {
      _interval = int.tryParse(config['interval']!) ?? 5;
    }
    if (config.containsKey('thermal_zone')) {
      _thermalZone = config['thermal_zone'];
    }
  }

  @override
  void update() {
    try {
      final zoneDir = _findThermalZone();
      if (zoneDir == null) {
        _display = 'N/A';
        output = _display;
        return;
      }
      final tempFile = File('$zoneDir/temp');
      final raw = tempFile.readAsStringSync().trim();
      final millidegrees = int.tryParse(raw);
      if (millidegrees == null) {
        _display = 'N/A';
        output = _display;
        return;
      }
      final celsius = millidegrees / 1000;
      _display = _format.replaceAll('{temp}', celsius.round().toString());
      output = _display;
    } catch (_) {
      _display = 'N/A';
      output = _display;
    }
  }

  String? _findThermalZone() {
    if (_thermalZone != null) {
      final path = '/sys/class/thermal/$_thermalZone';
      if (Directory(path).existsSync()) return path;
      return null;
    }

    final dir = Directory('/sys/class/thermal');
    if (!dir.existsSync()) return null;

    final entries = dir.listSync().whereType<Directory>().toList()
      ..sort((a, b) => a.path.compareTo(b.path));

    for (final entry in entries) {
      final name = entry.uri.pathSegments.last;
      if (name.startsWith('thermal_zone')) {
        return entry.path;
      }
    }

    return null;
  }
}
