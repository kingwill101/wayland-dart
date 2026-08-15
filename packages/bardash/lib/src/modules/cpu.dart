import 'dart:io';

import 'module.dart';

/// CPU usage via /proc/stat.
///
/// Tooltip shows the total up top then per-core usage (waybar-style):
///   CPU 12.3%
///   cpu0  5.2%
///   cpu1 10.8%
///   ...
/// `tooltip-format` placeholders: {usage}, {cores}.
class CpuModule extends BarModule {
  @override
  String get name => 'cpu';

  // Previous cumulative total-cpu counters (from the `cpu` line).
  int? _prevUser;
  int? _prevNice;
  int? _prevSystem;
  int? _prevIdle;
  int? _prevIowait;

  // Previous cumulative per-core counters, indexed by core number.
  final Map<int, List<int>> _prevCores = {};

  @override
  void init(Map<String, String> config) {
    super.init(config);
    // Waybar default is closer to "{usage}% " — keep a short label default.
    format = resolveFormat(config, '{usage}%', '');
    interval = parseInt(config, 'interval', 2);
  }

  /// Compute percentage from two cumulative counter snapshots.
  /// Returns null when there is no previous sample (first tick).
  static double? _percent(List<int> now, List<int> prev) {
    if (now.length < 5 || prev.length < 5) return null;
    final totalDelta =
        (now[0] - prev[0]) +
        (now[1] - prev[1]) +
        (now[2] - prev[2]) +
        (now[3] - prev[3]) +
        (now[4] - prev[4]);
    final idleDelta = now[3] - prev[3];
    if (totalDelta <= 0) return null;
    return (totalDelta - idleDelta) / totalDelta * 100;
  }

  @override
  void update() {
    try {
      final lines = File('/proc/stat').readAsStringSync().split('\n');
      if (lines.isEmpty) {
        output = 'ERR';
        return;
      }

      // ── Total CPU (first `cpu` line) ──────────────────────────────
      final parts = lines[0].split(RegExp(r'\s+'));
      if (parts.length < 5 || parts[0] != 'cpu') {
        output = 'ERR';
        return;
      }
      final totalNow = <int>[
        for (var i = 1; i <= 4; i++) int.tryParse(parts[i]) ?? 0,
        parts.length > 5 ? int.tryParse(parts[5]) ?? 0 : 0,
      ];

      var usageStr = '0.0';
      final totalPct = _percent(totalNow, [
        _prevUser ?? 0,
        _prevNice ?? 0,
        _prevSystem ?? 0,
        _prevIdle ?? 0,
        _prevIowait ?? 0,
      ]);
      if (_prevUser != null && totalPct != null) {
        usageStr = totalPct.toStringAsFixed(1);
      }

      _prevUser = totalNow[0];
      _prevNice = totalNow[1];
      _prevSystem = totalNow[2];
      _prevIdle = totalNow[3];
      _prevIowait = totalNow[4];

      output = format.replaceAll('{usage}', usageStr);

      // ── Per-core lines (waybar-style, total first) ────────────────
      final coreLines = <String>[];
      for (var i = 1; i < lines.length; i++) {
        final core = lines[i].split(RegExp(r'\s+'));
        if (core.length < 5 || !core[0].startsWith('cpu')) continue;
        final idx = int.tryParse(core[0].substring(3));
        if (idx == null) continue;
        final now = <int>[
          int.tryParse(core[1]) ?? 0,
          int.tryParse(core[2]) ?? 0,
          int.tryParse(core[3]) ?? 0,
          int.tryParse(core[4]) ?? 0,
          core.length > 5 ? int.tryParse(core[5]) ?? 0 : 0,
        ];
        final had = _prevCores.containsKey(idx);
        final prev = had ? _prevCores[idx]! : List.filled(5, 0);
        final pct = had ? _percent(now, prev) : null;
        _prevCores[idx] = now;
        // Align core name so percentages line up in a monospace tooltip.
        coreLines.add(
          '${core[0].padRight(6)}${pct == null ? '--' : pct.toStringAsFixed(1)}%',
        );
      }

      final coresText = coreLines.join('\n');
      tooltip = resolveTooltip(
        usageStr.isEmpty ? 'CPU n/a' : 'CPU $usageStr%\n$coresText',
        {'usage': usageStr, 'cores': coresText},
      );
    } catch (_) {
      output = 'N/A';
    }
  }
}
