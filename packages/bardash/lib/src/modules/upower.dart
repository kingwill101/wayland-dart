import 'package:window_toolkit/window_toolkit.dart';

import '../metrics.dart';
import '../native/upower_client.dart';
import 'module.dart';

/// Battery via **UPower D-Bus** (no `upower` CLI).
///
/// Placeholders: `{percentage}`, `{state}`, `{time}`, `{icon}`, `{model}`
///
/// Config: `device` — native path filter (e.g. `BAT0`) or UPower path fragment.
class UPowerModule extends BarModule {
  @override
  String get name => 'upower';

  String? _deviceFilter;
  UpDeviceSnapshot? _bat;
  void Function(UPowerSnapshot)? _listener;
  String _lastOut = '';

  @override
  void init(Map<String, String> config) {
    super.init(config);
    _deviceFilter = config['device'];
    format = resolveFormat(config, '{percentage}% {icon}', '');
    interval = parseInt(config, 'interval', 30);
    _listener = (s) {
      _bat = _pick(s);
      _apply();
    };
    UPowerClient.instance.addListener(_listener!);
  }

  UpDeviceSnapshot? _pick(UPowerSnapshot s) {
    if (s.batteries.isEmpty) return null;
    final f = _deviceFilter?.toUpperCase();
    if (f != null && f.isNotEmpty) {
      for (final b in s.batteries) {
        if (b.nativePath.toUpperCase() == f ||
            b.path.toUpperCase().contains(f)) {
          return b;
        }
      }
    }
    return s.primaryBattery;
  }

  @override
  void update() {
    UPowerClient.instance.refresh();
  }

  void _apply() {
    final b = _bat;
    if (b == null) {
      output = '';
      tooltip = '';
      _maybeRepaint();
      return;
    }
    final pct = b.percentage.round().clamp(0, 100);
    final stateKey = b.isCharging
        ? 'charging'
        : (b.state == UpDeviceState.fullyCharged ? 'full' : '');
    final fmt = resolveFormat(config, '{percentage}% {icon}', stateKey);
    final icon = b.isCharging
        ? '⚡'
        : (pct <= 15 ? '🪫' : '🔋');

    output = fmt
        .replaceAll('{percentage}', '$pct')
        .replaceAll('{state}', b.stateLabel)
        .replaceAll('{time}', b.timeLabel)
        .replaceAll('{icon}', icon)
        .replaceAll('{model}', b.model);

    tooltip = resolveTooltip(
      [
        '$pct% ${b.stateLabel}',
        if (b.timeLabel.isNotEmpty) b.timeLabel,
        if (b.model.isNotEmpty) b.model,
        if (UPowerClient.instance.last.onBattery) 'On battery',
      ].join(' · '),
      {
        'percentage': '$pct',
        'state': b.stateLabel,
        'time': b.timeLabel,
        'model': b.model,
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

  @override
  double measure(Painter painter) {
    if (output.isEmpty) return 0;
    final font = Font.ui(pixelSize: BarMetrics.current.fontSize);
    return painter.measureTextFont(output, font);
  }

  @override
  double draw(Painter painter, double x, double y) {
    if (output.isEmpty) return 0;
    final m = BarMetrics.current;
    final ui = Font.ui(pixelSize: m.fontSize);
    // Split emoji if present for correct spacing.
    final pct = _bat?.percentage.round().clamp(0, 100);
    if (pct == null) {
      painter.drawTextFont(output, Offset(x, y), font: ui);
      return painter.measureTextFont(output, ui);
    }
    final emoji = Font(family: m.emojiFamily, pixelSize: m.fontSize);
    final gap = m.iconTextGap.toDouble();
    final cap = '$pct%';
    final icon = _bat!.isCharging
        ? '⚡'
        : (pct <= 15 ? '🪫' : '🔋');
    final capW = painter.measureTextFont(cap, ui);
    final iconW = m.emojiLayoutWidth(painter.measureTextFont(icon, emoji));
    painter.drawTextFont(cap, Offset(x, y), font: ui);
    painter.drawTextFont(icon, Offset(x + capW + gap, y), font: emoji);
    return capW + gap + iconW;
  }
}
