import 'package:window_toolkit/window_toolkit.dart';

import '../metrics.dart';
import '../native/systemd_client.dart';
import 'module.dart';

/// Failed systemd units via D-Bus (`NFailedUnits` / `ListUnitsFiltered`).
///
/// No `systemctl` subprocess. Hides when count is 0.
///
/// Placeholders: `{count}`, `{icon}`, `{units}`
class SystemdFailedModule extends BarModule {
  @override
  String get name => 'systemd-failed';

  SystemdFailedSnapshot _snap = SystemdFailedSnapshot.unavailable;
  void Function(SystemdFailedSnapshot)? _listener;
  String _lastOut = '';

  @override
  void init(Map<String, String> config) {
    super.init(config);
    format = resolveFormat(config, '\u{F071} {count}', '');
    // Signal-driven; long poll as backup.
    interval = parseInt(config, 'interval', 60);
    _listener = (s) {
      _snap = s;
      _apply();
    };
    SystemdClient.instance.addListener(_listener!);
  }

  @override
  void update() {
    SystemdClient.instance.refresh();
  }

  void _apply() {
    if (!_snap.available || _snap.count == 0) {
      output = '';
      tooltip = '';
      _maybeRepaint();
      return;
    }
    final units = _snap.unitNames.join(', ');
    output = format
        .replaceAll('{count}', '${_snap.count}')
        .replaceAll('{icon}', '\u{F071}')
        .replaceAll('{units}', units);
    tooltip = resolveTooltip(
      units.isNotEmpty
          ? 'Failed units (${_snap.count}): $units'
          : 'Failed units: ${_snap.count}',
      {'count': '${_snap.count}', 'units': units},
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
    painter.drawTextFont(
      output,
      Offset(x, y),
      font: font,
      color: const Color(255, 200, 60),
    );
    return painter.measureTextFont(output, font);
  }
}
