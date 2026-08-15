import '../native/gamemode_client.dart';
import 'module.dart';

/// Feral GameMode status — runtime file / session D-Bus (no `gamemoded -s`).
///
/// Placeholders: `{count}`, `{icon}`
/// Formats: `format`, `format-active`
class GamemodeModule extends BarModule {
  @override
  String get name => 'gamemode';

  GamemodeSnapshot _snap = GamemodeSnapshot.empty;
  String _lastOut = '';

  @override
  void init(Map<String, String> config) {
    super.init(config);
    format = resolveFormat(config, '{icon}', '');
    interval = parseInt(config, 'interval', 5);
  }

  @override
  void update() {
    GamemodeClient.instance.refresh().then((s) {
      _snap = s;
      _apply();
    });
  }

  void _apply() {
    if (!_snap.available && !_snap.active) {
      // Still show inactive icon if we have no daemon — optional empty.
      // Match previous behaviour: show icon (gray) when we can detect.
      output = '';
      tooltip = '';
      _maybeRepaint();
      return;
    }

    final active = _snap.active;
    final fmt = active ? resolveFormat(config, format, 'active') : format;
    final icon = '\u{F11B}';

    output = fmt
        .replaceAll('{icon}', icon)
        .replaceAll('{count}', '${_snap.clientCount}');
    tooltip = active
        ? 'GameMode active (${_snap.clientCount} clients)'
        : 'GameMode inactive';
    _maybeRepaint();
  }

  void _maybeRepaint() {
    if (output != _lastOut) {
      _lastOut = output;
      requestRepaint?.call();
    }
  }
}
