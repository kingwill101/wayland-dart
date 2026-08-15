/// Live link throughput from /proc/net/dev (rx/tx deltas between samples).
///
/// Shared by the network module (bar/tooltip `{up}`/`{down}` placeholders)
/// and the network popup. [formatRate] is unit-testable headless.
library;

import 'dart:io';

class NetSpeed {
  NetSpeed._();

  /// Which interface to track; empty → first non-loopback found.
  static String activeIface = '';

  static int _prevRx = -1;
  static int _prevTx = -1;
  static DateTime? _prevAt;

  /// Last rx rate in bytes/second (into the machine).
  static double downBps = 0;

  /// Last tx rate in bytes/second out of the machine.
  static double upBps = 0;

  static bool get hasSample => _prevRx >= 0 && _prevTx >= 0;

  /// Take a sample reading rx/tx for (iface | @iface) and update rates.
  static void sample() {
    int? rx;
    int? tx;
    try {
      for (final line in File('/proc/net/dev').readAsStringSync().split('\n')) {
        if (activeIface.isNotEmpty && !line.startsWith('$activeIface:')) {
          continue;
        }
        final m = RegExp(
                r'^\s*([^:\s]+):\s+(\d+)\s+\d+\s+\d+\s+\d+\s+\d+\s+\d+\s+\d+\s+\d+\s+(\d+)')
            .firstMatch(line);
        if (m == null) continue;
        final name = m.group(1)!;
        if (activeIface.isEmpty && name == 'lo') continue;
        rx = int.parse(m.group(2)!);
        tx = int.parse(m.group(3)!);
        if (activeIface.isEmpty) activeIface = name; // first real iface
        break;
      }
    } catch (_) {}

    final now = DateTime.now();
    if (rx != null &&
        tx != null &&
        _prevRx >= 0 &&
        _prevTx >= 0 &&
        _prevAt != null) {
      final dt = now.difference(_prevAt!).inMilliseconds / 1000.0;
      if (dt > 0) {
        downBps = ((rx - _prevRx) / dt).clamp(0, double.infinity);
        upBps = ((tx - _prevTx) / dt).clamp(0, double.infinity);
      }
    }
    _prevRx = rx ?? -1;
    _prevTx = tx ?? -1;
    _prevAt = now;
  }

  /// "1.4 MB/s", "823.0 KB/s", "12 B/s".
  static String formatRate(double bytesPerSec) {
    if (bytesPerSec >= 1024 * 1024) {
      return '${(bytesPerSec / (1024 * 1024)).toStringAsFixed(1)} MB/s';
    }
    if (bytesPerSec >= 1024) {
      return '${(bytesPerSec / 1024).toStringAsFixed(1)} KB/s';
    }
    return '${bytesPerSec.round()} B/s';
  }
}