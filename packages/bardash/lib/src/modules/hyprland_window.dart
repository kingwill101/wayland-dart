import 'package:window_toolkit/window_toolkit.dart';

import '../native/hyprland_ipc.dart' as ipc;
import 'module.dart';

/// Hyprland focused window title via direct IPC.
///
/// Truncates long titles with an ellipsis (configurable via `max-width`).
class HyprlandWindowModule extends BarModule {
  @override
  String get name => 'hyprland/window';

  String _title = '';
  int _maxWidth = 200; // pixels

  @override
  void init(Map<String, String> config) {
    super.init(config);
    format = resolveFormat(config, '{title}', '');
    interval = 1;
    _maxWidth = parseInt(config, 'max-width', 200);
  }

  @override
  void update() {
    final data = ipc.hyprctl('activewindow');
    if (data is! Map || data['mapped'] != true) {
      widget = null;
      output = '';
      return;
    }

    _title = data['title']?.toString() ?? '';
    final cls = data['class']?.toString() ?? '';

    output = format.replaceAll('{title}', _title).replaceAll('{class}', cls);

    widget = _buildLabel();
  }

  Widget _buildLabel() =>
      Label(_title, font: const Font.ui(pixelSize: 14), maxWidth: _maxWidth);
}
