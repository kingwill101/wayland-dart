import 'package:window_toolkit/window_toolkit.dart';

import '../native/hyprland_ipc.dart' as ipc;
import 'module.dart';

/// Hyprland keyboard layout indicator via direct IPC.
class HyprlandLanguageModule extends BarModule {
  @override
  String get name => 'hyprland/language';

  String _layout = '';

  @override
  void init(Map<String, String> config) {
    super.init(config);
    format = resolveFormat(config, '{short}', '');
    interval = parseInt(config, 'interval', 1);
  }

  @override
  void update() {
    final data = ipc.hyprctl('devices');
    if (data is! Map) { output = ''; return; }

    final keyboards = data['keyboards'] as List?;
    if (keyboards == null) { output = ''; return; }

    for (final kb in keyboards) {
      final name = kb['name']?.toString() ?? '';
      final keymap = kb['active_keymap']?.toString();
      if (keymap != null && keymap.isNotEmpty && !name.contains('virtual')) {
        _layout = keymap;
        break;
      }
    }

    if (_layout.isEmpty) { output = ''; return; }

    final short = _layout.length >= 2
        ? _layout.substring(0, 2).toUpperCase()
        : _layout.toUpperCase();

    output = format
        .replaceAll('{layout}', _layout)
        .replaceAll('{short}', short);
  }

  @override
  double draw(Painter painter, double x, double y) {
    if (output.isEmpty) return 0;
    painter.drawText(output, Offset(x, y));
    return painter.measureText(output).width;
  }
}
