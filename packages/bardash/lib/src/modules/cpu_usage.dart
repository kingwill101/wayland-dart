import 'dart:io';

import 'package:window_toolkit/window_toolkit.dart';

import 'module.dart';

class _CpuData {
  final int user;
  final int nice;
  final int system;
  final int idle;
  final int iowait;

  _CpuData(this.user, this.nice, this.system, this.idle, this.iowait);
}

class CpuUsageModule extends BarModule {
  @override
  String get name => 'cpu-usage';

  Map<int, _CpuData> _prevData = {};
  final Map<int, double> _coreUsage = {};
  double _totalUsage = 0.0;

  @override
  void init(Map<String, String> config) {
    super.init(config);
    format = resolveFormat(config, '{usage}%', '');
    interval = parseInt(config, 'interval', 1);
  }

  @override
  void update() {
    try {
      final lines = File('/proc/stat').readAsStringSync().split('\n');
      final currentData = <int, _CpuData>{};
      double totalUsage = 0.0;
      int coreCount = 0;

      for (final line in lines) {
        final parts = line.split(RegExp(r'\s+'));
        if (parts.length < 5) continue;
        if (!parts[0].startsWith('cpu') || parts[0] == 'cpu') continue;

        final index = int.tryParse(parts[0].substring(3));
        if (index == null) continue;

        final user = int.tryParse(parts[1]) ?? 0;
        final nice = int.tryParse(parts[2]) ?? 0;
        final system = int.tryParse(parts[3]) ?? 0;
        final idle = int.tryParse(parts[4]) ?? 0;
        final iowait = parts.length > 5 ? int.tryParse(parts[5]) ?? 0 : 0;

        currentData[index] = _CpuData(user, nice, system, idle, iowait);

        final prev = _prevData[index];
        if (prev != null) {
          final totalDelta = (user - prev.user) +
              (nice - prev.nice) +
              (system - prev.system) +
              (idle - prev.idle) +
              (iowait - prev.iowait);
          final idleDelta = idle - prev.idle;
          if (totalDelta > 0) {
            final usage = (totalDelta - idleDelta) / totalDelta * 100;
            _coreUsage[index] = usage;
            totalUsage += usage;
            coreCount++;
          }
        } else {
          _coreUsage[index] = 0.0;
        }
      }

      _prevData = currentData;

      if (coreCount > 0) {
        _totalUsage = totalUsage / coreCount;
      }

      _buildOutput();
    } catch (_) {
      output = 'N/A';
    }
  }

  void _buildOutput() {
    var result = format.replaceAll('{usage}', _totalUsage.toStringAsFixed(1));

    for (var i = 0; i < 8; i++) {
      final usage = _coreUsage[i];
      result = result.replaceAll(
          '{core$i}',
          usage != null ? usage.toStringAsFixed(0) : '0');
    }

    final icon = getIcon(_totalUsage.round(), ['', '', '', '']);
    result = result.replaceAll('{icon}', icon);

    output = result;
  }

  @override
  double draw(Painter painter, double x, double y) {
    painter.drawText(output, Offset(x, y));
    return painter.measureText(output).width;
  }
}
