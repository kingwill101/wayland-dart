import 'dart:io';

import 'package:window_toolkit/window_toolkit.dart';

import '../metrics.dart';
import 'module.dart';

class CpuModule extends BarModule {
  @override
  String get name => 'cpu';

  int? _prevUser;
  int? _prevNice;
  int? _prevSystem;
  int? _prevIdle;
  int? _prevIowait;

  @override
  void init(Map<String, String> config) {
    super.init(config);
    // Waybar default is closer to "{usage}% " — keep a short label default.
    format = resolveFormat(config, '{usage}%', '');
    interval = parseInt(config, 'interval', 2);
  }

  @override
  void update() {
    try {
      final line = File('/proc/stat').readAsStringSync().split('\n')[0];
      final parts = line.split(RegExp(r'\s+'));
      if (parts.length < 5 || parts[0] != 'cpu') {
        output = 'ERR';
        return;
      }
      final user = int.tryParse(parts[1]) ?? 0;
      final nice = int.tryParse(parts[2]) ?? 0;
      final system = int.tryParse(parts[3]) ?? 0;
      final idle = int.tryParse(parts[4]) ?? 0;
      final iowait = parts.length > 5 ? int.tryParse(parts[5]) ?? 0 : 0;

      var usageStr = '0.0';
      if (_prevUser != null) {
        final totalDelta = (user - _prevUser!) +
            (nice - _prevNice!) +
            (system - _prevSystem!) +
            (idle - _prevIdle!) +
            (iowait - _prevIowait!);
        final idleDelta = (idle - _prevIdle!);
        if (totalDelta > 0) {
          final usage = (totalDelta - idleDelta) / totalDelta * 100;
          usageStr = usage.toStringAsFixed(1);
        }
      }

      _prevUser = user;
      _prevNice = nice;
      _prevSystem = system;
      _prevIdle = idle;
      _prevIowait = iowait;

      output = format.replaceAll('{usage}', usageStr);
      tooltip = resolveTooltip(
        'CPU $usageStr%',
        {'usage': usageStr},
      );
    } catch (_) {
      output = 'N/A';
    }
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
