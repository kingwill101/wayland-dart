import 'dart:io';

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
    _user =
        Platform.environment['USER'] ?? Platform.environment['LOGNAME'] ?? '';
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
      _user =
          Platform.environment['USER'] ?? Platform.environment['LOGNAME'] ?? '';
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
    tooltip = resolveTooltip('$_user@$_hostname', {
      'user': _user,
      'hostname': _hostname,
      'home': _home,
    });
  }
}
