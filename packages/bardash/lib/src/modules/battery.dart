import 'dart:io';

import 'package:window_toolkit/window_toolkit.dart';

import '../metrics.dart';
import '../native/upower_client.dart';
import 'module.dart';

/// Battery status — prefers **UPower D-Bus**, falls back to sysfs `BAT*`.
///
/// Placeholders: `{capacity}`, `{status}`, `{icon}`, `{time}`, `{model}`
class BatteryModule extends BarModule {
  @override
  String get name => 'battery';

  String _bat = 'BAT0';
  int? _capacity;
  String _status = 'Unknown';
  bool _isCharging = false;
  String _time = '';
  String _model = '';
  void Function(UPowerSnapshot)? _listener;
  String _lastOut = '';
  bool _useSysfs = false;

  @override
  void init(Map<String, String> config) {
    super.init(config);
    if (config.containsKey('bat')) _bat = config['bat']!;
    format = resolveFormat(config, '{capacity}%{icon}', '');
    // UPower is signal-driven; light poll as backup / sysfs mode.
    interval = parseInt(config, 'interval', 15);
    _listener = (s) {
      final b = _pickBattery(s);
      if (b == null) {
        if (!_trySysfs()) {
          output = '';
          tooltip = '';
          _maybeRepaint();
        }
        return;
      }
      _useSysfs = false;
      _capacity = b.percentage.round().clamp(0, 100);
      _status = b.stateLabel;
      _isCharging = b.isCharging;
      _time = b.timeLabel;
      _model = b.model;
      _applyFormat();
    };
    UPowerClient.instance.addListener(_listener!);
  }

  UpDeviceSnapshot? _pickBattery(UPowerSnapshot s) {
    if (s.batteries.isEmpty) return null;
    final want = _bat.toUpperCase();
    for (final b in s.batteries) {
      if (b.nativePath.toUpperCase() == want ||
          b.path.toUpperCase().contains(want)) {
        return b;
      }
    }
    return s.primaryBattery;
  }

  bool _trySysfs() {
    try {
      final capFile = File('/sys/class/power_supply/$_bat/capacity');
      final statusFile = File('/sys/class/power_supply/$_bat/status');
      if (!capFile.existsSync() || !statusFile.existsSync()) return false;
      _capacity = int.tryParse(capFile.readAsStringSync().trim());
      _status = statusFile.readAsStringSync().trim();
      _isCharging = _status == 'Charging';
      _time = '';
      _model = _bat;
      _useSysfs = true;
      if (_capacity == null) return false;
      _applyFormat();
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  void update() {
    if (_useSysfs) {
      _trySysfs();
    } else {
      UPowerClient.instance.refresh();
    }
  }

  void _applyFormat() {
    if (_capacity == null) {
      output = '';
      return;
    }
    final state = _isCharging
        ? 'charging'
        : (_status.toLowerCase().contains('full') ? 'full' : '');
    final fmt = resolveFormat(config, '{capacity}%{icon}', state);
    output = fmt
        .replaceAll('{capacity}', '$_capacity')
        .replaceAll('{status}', _status)
        .replaceAll('{icon}', _icon)
        .replaceAll('{time}', _time)
        .replaceAll('{model}', _model);
    tooltip = resolveTooltip(
      [
        '$_capacity% $_status',
        if (_time.isNotEmpty) _time,
        if (_model.isNotEmpty) _model,
      ].join(' · '),
      {
        'capacity': '$_capacity',
        'status': _status,
        'icon': _icon,
        'time': _time,
        'model': _model,
      },
    );
    _maybeRepaint();
  }

  void _maybeRepaint() {
    if (output != _lastOut) {
      _lastOut = output;
      requestRepaint?.call();
    }
  }

  String get _icon {
    if (_capacity == null) return '?';
    if (_isCharging) return '⚡';
    if (_capacity! <= 15) return '🪫';
    return '🔋';
  }

  @override
  double measure(Painter painter) {
    if (output.isEmpty) return 0;
    final m = BarMetrics.current;
    final ui = Font.ui(pixelSize: m.fontSize);
    if (_capacity == null) return painter.measureTextFont(output, ui);
    final emoji = Font(family: m.emojiFamily, pixelSize: m.fontSize);
    final gap = m.iconTextGap.toDouble();
    final capW = painter.measureTextFont('$_capacity%', ui);
    final iconW = m.emojiLayoutWidth(painter.measureTextFont(_icon, emoji));
    return capW + gap + iconW;
  }

  @override
  double draw(Painter painter, double x, double y) {
    if (output.isEmpty) return 0;
    final m = BarMetrics.current;
    final ui = Font.ui(pixelSize: m.fontSize);
    final emoji = Font(family: m.emojiFamily, pixelSize: m.fontSize);
    final gap = m.iconTextGap.toDouble();
    const color = Color(180, 180, 180);
    if (_capacity == null) {
      painter.drawTextFont(output, Offset(x, y), font: ui, color: color);
      return painter.measureTextFont(output, ui);
    }
    final cap = '$_capacity%';
    final capW = painter.measureTextFont(cap, ui);
    final iconW = m.emojiLayoutWidth(painter.measureTextFont(_icon, emoji));
    painter.drawTextFont(cap, Offset(x, y), font: ui, color: color);
    painter.drawTextFont(
      _icon,
      Offset(x + capW + gap, y),
      font: emoji,
      color: color,
    );
    return capW + gap + iconW;
  }
}
