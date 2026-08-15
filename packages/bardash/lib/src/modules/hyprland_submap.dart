import '../native/hyprland_ipc.dart' as ipc;
import 'module.dart';

/// Hyprland submap indicator via direct IPC.
class HyprlandSubmapModule extends BarModule {
  @override
  String get name => 'hyprland/submap';

  String _submap = '';
  Map<String, String> _icons = {};
  bool _available = true;

  static const _defaultIcons = <String, String>{
    'resize': '\u2194',
    'move': '\u2794',
  };

  @override
  void init(Map<String, String> config) {
    super.init(config);
    format = resolveFormat(config, '{icon}', '');
    interval = parseInt(config, 'interval', 1);
    for (final entry in _defaultIcons.entries) {
      _icons[entry.key] = config[entry.key] ?? entry.value;
    }
  }

  @override
  void update() {
    if (!_available) {
      output = '';
      return;
    }

    final binds = ipc.hyprctl('binds');
    if (binds is! List) {
      _available = false;
      output = '';
      return;
    }

    final hasSubmap = binds.any((b) {
      final s = b['submap']?.toString() ?? '';
      return s.isNotEmpty;
    });

    _submap = hasSubmap ? 'resize' : '';
    final fmt = _submap.isEmpty
        ? resolveFormat(
            {'format': format, 'format-default': ''},
            format,
            'default',
          )
        : format;

    if (_submap.isEmpty && fmt == format) {
      output = '';
      return;
    }

    output = fmt
        .replaceAll('{submap}', _submap)
        .replaceAll('{icon}', _icons[_submap] ?? '\u2194');
  }
}
