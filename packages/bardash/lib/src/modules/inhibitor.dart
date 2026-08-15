import 'dart:io';

import 'module.dart';

/// Logind idle inhibitor module.
///
/// Shows whether an idle inhibitor is active (preventing the system from
/// suspending/idling). Uses `systemd-inhibit --list` to detect active
/// inhibitors.
///
/// Unlike `idle-inhibitor` which handles the Wayland idle-inhibit protocol,
/// this module tracks systemd/logind sleep inhibition.
///
/// Format placeholders:
///   {count}   – number of active inhibitors (0 = inactive)
///   {who}     – first inhibitor's "who" field (e.g. "firefox")
///   {icon}    – lock icon
///
/// Config keys:
///   format          – display format (default: "{icon}")
///   interval        – refresh in seconds (default: 10)
///   on-click        – command on click
class InhibitorModule extends BarModule {
  @override
  String get name => 'inhibitor';

  int _count = 0;
  String _who = '';

  @override
  void init(Map<String, String> config) {
    super.init(config);
    format = resolveFormat(config, '{icon}', '');
    interval = parseInt(config, 'interval', 10);
  }

  @override
  void update() {
    try {
      final result = Process.runSync('systemd-inhibit', [
        '--list',
        '--no-legend',
      ], runInShell: true);

      if (result.exitCode != 0) {
        output = '';
        return;
      }

      final lines = (result.stdout as String)
          .split('\n')
          .where((l) => l.trim().isNotEmpty)
          .toList();

      // Filter out our own inhibition
      _count = lines.where((l) => !l.contains('bardash')).length;
      _who = _count > 0 ? lines.first.trim().split(RegExp(r'\s+')).first : '';

      final icon = _count > 0 ? '\uF023' : '\uF09C'; // lock / unlock

      output = format
          .replaceAll('{icon}', icon)
          .replaceAll('{count}', _count.toString())
          .replaceAll('{who}', _who);
    } catch (_) {
      output = '';
    }
  }
}
