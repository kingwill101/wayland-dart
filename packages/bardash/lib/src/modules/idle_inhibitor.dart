import 'dart:io';

import 'module.dart';

class IdleInhibitorModule extends BarModule {
  @override
  String get name => 'idle-inhibitor';

  bool _activated = false;
  String _formatActivated = '\uF06E';
  String _formatDeactivated = '\uF070';
  String _cmdOnClick = '';

  @override
  void init(Map<String, String> config) {
    super.init(config);
    format = resolveFormat(config, '{icon}', 'deactivated');
    _formatActivated = config['format-activated'] ?? _formatActivated;
    _formatDeactivated = config['format-deactivated'] ?? _formatDeactivated;
    _cmdOnClick = config['on-click'] ?? '';
    output = _formatState();
  }

  @override
  void update() {
    output = _formatState();
  }

  @override
  bool get hasClick => true;

  @override
  void onClick(double x, double y, {int button = 0x110}) {
    _activated = !_activated;
    output = _formatState();
    if (_cmdOnClick.isNotEmpty) {
      final parts = _cmdOnClick.split(' ');
      if (parts.isNotEmpty) {
        Process.run(
          parts.first,
          parts.skip(1).toList(),
        ).then((_) {}).catchError((_) {});
      }
    }
  }

  String _formatState() {
    final icon = _activated ? _formatActivated : _formatDeactivated;
    return format.replaceAll('{icon}', icon);
  }
}
