import 'dart:io';

import 'module.dart';

class CpuFrequencyModule extends BarModule {
  @override
  String get name => 'cpu-frequency';

  @override
  void init(Map<String, String> config) {
    super.init(config);
    format = resolveFormat(config, '{freq} MHz', '');
    interval = parseInt(config, 'interval', 2);
  }

  @override
  void update() {
    try {
      final cpuDir = Directory('/sys/devices/system/cpu/cpu0/cpufreq');
      if (!cpuDir.existsSync()) {
        output = 'N/A';
        return;
      }

      final freqKhz = File(
        '${cpuDir.path}/scaling_cur_freq',
      ).readAsStringSync().trim();
      final freqMhz = (int.tryParse(freqKhz) ?? 0) ~/ 1000;

      late final String minMhz;
      late final String maxMhz;
      late final String governor;

      try {
        final minKhz = File(
          '${cpuDir.path}/scaling_min_freq',
        ).readAsStringSync().trim();
        minMhz = ((int.tryParse(minKhz) ?? 0) ~/ 1000).toString();
      } catch (_) {
        minMhz = '?';
      }

      try {
        final maxKhz = File(
          '${cpuDir.path}/scaling_max_freq',
        ).readAsStringSync().trim();
        maxMhz = ((int.tryParse(maxKhz) ?? 0) ~/ 1000).toString();
      } catch (_) {
        maxMhz = '?';
      }

      try {
        governor = File(
          '${cpuDir.path}/scaling_governor',
        ).readAsStringSync().trim();
      } catch (_) {
        governor = '?';
      }

      output = format
          .replaceAll('{freq}', freqMhz.toString())
          .replaceAll('{min}', minMhz)
          .replaceAll('{max}', maxMhz)
          .replaceAll('{governor}', governor);
    } catch (_) {
      output = 'N/A';
    }
  }
}
