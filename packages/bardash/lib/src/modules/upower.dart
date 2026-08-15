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
    final icon = _iconFor(b.isCharging, pct);

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

  String _iconFor(bool charging, int percentage) {
    if (charging) return '\u{f0e7}';
    if (percentage <= 15) return '\u{f244}';
    return '\u{f240}';
  }
}
