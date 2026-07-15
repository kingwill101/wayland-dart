import 'dart:io';

import 'package:window_toolkit/window_toolkit.dart';

import '../metrics.dart';
import 'module.dart';

/// Current user / host — env + [Platform] only (no `whoami` / `hostname`).
///
/// Placeholders: `{user}`, `{hostname}`, `{home}`
class UserModule extends BarModule {
  @override
  String get name => 'user';

  String _user = '';
  String _hostname = '';
  String _home = '';

  @override
  void init(Map<String, String> config) {
    super.init(config);
    format = resolveFormat(config, '{user}', '');
    // Values are static for the process lifetime.
    interval = parseInt(config, 'interval', 3600);
    _user = Platform.environment['USER'] ??
        Platform.environment['LOGNAME'] ??
        '';
    _home = Platform.environment['HOME'] ?? '';
    try {
      _hostname = Platform.localHostname;
    } catch (_) {
      _hostname = Platform.environment['HOSTNAME'] ?? '';
    }
    _apply();
  }

  @override
  void update() {
    // Re-read only if somehow empty (container edge cases).
    if (_user.isEmpty) {
      _user = Platform.environment['USER'] ??
          Platform.environment['LOGNAME'] ??
          '';
    }
    if (_hostname.isEmpty) {
      try {
        _hostname = Platform.localHostname;
      } catch (_) {}
    }
    _apply();
  }

  void _apply() {
    output = format
        .replaceAll('{user}', _user)
        .replaceAll('{hostname}', _hostname)
        .replaceAll('{home}', _home);
    tooltip = resolveTooltip(
      '$_user@$_hostname',
      {'user': _user, 'hostname': _hostname, 'home': _home},
    );
  }

  @override
  double measure(Painter painter) {
    if (output.isEmpty) return 0;
    final font = Font.ui(pixelSize: BarMetrics.current.fontSize);
    return painter.measureTextFont(output, font);
  }

  @override
  double draw(Painter painter, double x, double y) {
    if (output.isEmpty) return 0;
    final font = Font.ui(pixelSize: BarMetrics.current.fontSize);
    painter.drawTextFont(
      output,
      Offset(x, y),
      font: font,
      color: const Color(180, 180, 180),
    );
    return painter.measureTextFont(output, font);
  }
}
