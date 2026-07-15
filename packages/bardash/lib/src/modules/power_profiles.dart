import 'package:window_toolkit/window_toolkit.dart';

import '../command.dart';
import '../metrics.dart';
import '../native/power_profiles_client.dart';
import 'module.dart';

/// power-profiles-daemon status via D-Bus (no `powerprofilesctl`).
///
/// Placeholders: `{profile}`, `{icon}`
/// Left click: cycle profile (or `on-click` command).
class PowerProfilesModule extends BarModule {
  @override
  String get name => 'power-profiles-daemon';

  PowerProfilesSnapshot _snap = PowerProfilesSnapshot.unavailable;
  void Function(PowerProfilesSnapshot)? _listener;
  String _lastOut = '';

  static const _icons = <String, String>{
    'performance': '󰓅',
    'balanced': '󰾅',
    'power-saver': '󰌪',
  };

  @override
  void init(Map<String, String> config) {
    super.init(config);
    format = resolveFormat(config, '{icon}', '');
    interval = parseInt(config, 'interval', 30);
    _listener = (s) {
      _snap = s;
      _apply();
    };
    PowerProfilesClient.instance.addListener(_listener!);
  }

  @override
  void update() {
    PowerProfilesClient.instance.refresh();
  }

  void _apply() {
    if (!_snap.available) {
      output = '';
      tooltip = 'power-profiles-daemon not available';
      _maybeRepaint();
      return;
    }
    final profile = _snap.active;
    final fmt = resolveFormat(config, '{icon}', profile);
    output = fmt
        .replaceAll('{profile}', profile)
        .replaceAll('{icon}', _icons[profile] ?? '󰚥');
    tooltip = resolveTooltip(
      'Power profile: $profile\n${_snap.profiles.join(', ')}',
      {'profile': profile},
    );
    _maybeRepaint();
  }

  void _maybeRepaint() {
    if (output != _lastOut) {
      _lastOut = output;
      requestRepaint?.call();
    }
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
    painter.drawTextFont(output, Offset(x, y), font: font);
    return painter.measureTextFont(output, font);
  }

  @override
  void onClick(double x, double y, {int button = 0x110}) {
    if (onClickCmd.isNotEmpty) {
      runBarCommand(onClickCmd);
      return;
    }
    PowerProfilesClient.instance.cycleNext();
  }
}
