import '../native/hyprland_ipc.dart' as ipc;
import 'module.dart';

/// Hyprland window count via direct IPC.
class HyprlandWindowCountModule extends BarModule {
  @override
  String get name => 'hyprland/windowcount';

  int _count = 0;
  String _workspaceName = '';

  @override
  void init(Map<String, String> config) {
    super.init(config);
    format = resolveFormat(config, '{icon} {count}', '');
    interval = parseInt(config, 'interval', 1);
  }

  @override
  void update() {
    final ws = ipc.hyprctl('activeworkspace');
    if (ws is! Map) {
      output = '';
      return;
    }

    _workspaceName = ws['name']?.toString() ?? '';
    _count = ws['windows'] as int? ?? 0;

    final icon = _count > 0 ? '\u25A2' : '\u25A1';
    output = format
        .replaceAll('{count}', _count.toString())
        .replaceAll('{icon}', icon)
        .replaceAll('{workspace}', _workspaceName);
  }
}
