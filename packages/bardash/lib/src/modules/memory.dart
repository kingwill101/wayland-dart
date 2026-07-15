import 'dart:io';

import 'package:window_toolkit/window_toolkit.dart';

import '../metrics.dart';
import 'module.dart';

class MemoryModule extends BarModule {
  @override
  String get name => 'memory';

  @override
  void init(Map<String, String> config) {
    super.init(config);
    // Waybar uses "{}%" for memory percent — support both {percent} and {}.
    format = resolveFormat(config, '{percent}%', '');
    interval = parseInt(config, 'interval', 3);
  }

  @override
  void update() {
    try {
      final data = File('/proc/meminfo').readAsStringSync();
      int? memTotal;
      int? memAvailable;

      for (final line in data.split('\n')) {
        if (line.startsWith('MemTotal:')) {
          memTotal = _parseMeminfoValue(line);
        } else if (line.startsWith('MemAvailable:')) {
          memAvailable = _parseMeminfoValue(line);
        }
      }

      if (memTotal == null || memAvailable == null || memTotal == 0) {
        output = 'ERR';
        return;
      }

      final used = memTotal - memAvailable;
      final percent = used / memTotal * 100;
      final percentStr = percent.toStringAsFixed(1);
      final usedMiB = (used / 1024).toStringAsFixed(0);
      final totalMiB = (memTotal / 1024).toStringAsFixed(0);

      output = format
          .replaceAll('{percent}', percentStr)
          .replaceAll('{}', percentStr)
          .replaceAll('{used}', usedMiB)
          .replaceAll('{total}', totalMiB);
      tooltip = resolveTooltip(
        'Memory $percentStr% ($usedMiB / $totalMiB MiB)',
        {
          'percent': percentStr,
          'used': usedMiB,
          'total': totalMiB,
        },
      );
    } catch (_) {
      output = 'N/A';
    }
  }

  int _parseMeminfoValue(String line) {
    final parts = line.split(RegExp(r'\s+'));
    return int.tryParse(parts[1]) ?? 0;
  }

  @override
  double measure(Painter painter) {
    final font = Font.ui(pixelSize: BarMetrics.current.fontSize);
    return painter.measureTextFont(output, font);
  }

  @override
  double draw(Painter painter, double x, double y) {
    final font = Font.ui(pixelSize: BarMetrics.current.fontSize);
    painter.drawTextFont(output, Offset(x, y), font: font);
    return painter.measureTextFont(output, font);
  }
}
