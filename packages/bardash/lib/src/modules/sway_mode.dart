import 'dart:io';

import 'package:window_toolkit/window_toolkit.dart';

import 'module.dart';

/// Sway mode indicator.
///
/// Uses `swaymsg -t get_binding_state --raw` or inspects the tree for
/// the current binding mode ("default" when no special mode is active).
///
/// Format placeholders:
///   {mode}   – current mode name (empty when "default")
///
/// Config keys:
///   format          – display format (default: "{mode}")
///   format-default  – format when mode is "default" (default: "", hidden)
///   interval        – refresh in seconds (default: 1)
class SwayModeModule extends BarModule {
  @override
  String get name => 'sway/mode';

  String _mode = '';
  String _binary = 'swaymsg';

  @override
  void init(Map<String, String> config) {
    super.init(config);
    format = resolveFormat(config, '{mode}', '');
    interval = parseInt(config, 'interval', 1);
    _binary = _detectBinary();
  }

  String _detectBinary() {
    for (final bin in ['swaymsg', 'i3-msg']) {
      final which = Process.runSync('which', [bin], runInShell: true);
      if (which.exitCode == 0) return bin;
    }
    return 'swaymsg';
  }

  @override
  void update() {
    try {
      final result = Process.runSync(
        _binary,
        ['-t', 'get_binding_state', '--raw'],
        runInShell: true,
      );
      if (result.exitCode != 0) {
        output = '';
        return;
      }

      _mode = (result.stdout as String).trim();
      final fmt = _mode == 'default'
          ? resolveFormat(
              {'format': format, 'format-default': ''}, format, 'default')
          : format;

      output = fmt.replaceAll('{mode}', _mode);
    } catch (_) {
      output = '';
    }
  }

  @override
  double draw(Painter painter, double x, double y) {
    if (output.isEmpty) return 0;
    painter.drawText(output, Offset(x, y));
    return painter.measureText(output).width;
  }
}
