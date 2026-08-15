import '../command.dart';
import '../native/bluez.dart';
import 'module.dart';

/// Bluetooth status via BlueZ D-Bus (no `bluetoothctl`).
///
/// Placeholders:
///   {icon} {power} {device_count} {device} {devices}
class BluetoothModule extends BarModule {
  @override
  String get name => 'bluetooth';

  BluezSnapshot _snap = const BluezSnapshot(
    powered: false,
    adapterName: '',
    devices: [],
  );
  void Function(BluezSnapshot)? _listener;
  String _lastOut = '';

  @override
  void init(Map<String, String> config) {
    super.init(config);
    format = resolveFormat(config, ' {device_count}', '');
    // Signal-driven; light poll only as fallback.
    interval = parseInt(config, 'interval', 30);
    _listener = (s) {
      _snap = s;
      _apply();
    };
    BluezClient.instance.addListener(_listener!);
  }

  @override
  void update() {
    // Fallback refresh if signals missed.
    BluezClient.instance.refresh();
  }

  void _apply() {
    final powered = _snap.powered;
    final count = _snap.connectedCount;
    final device = _snap.primaryName;
    final devices = _snap.connected.map((d) => d.name).join(', ');
    final icon = powered ? (count > 0 ? '' : '') : '';
    final power = powered ? 'on' : 'off';

    final state = !powered ? 'off' : (count > 0 ? 'connected' : 'on');
    final fmt = resolveFormat(
      config,
      format.isNotEmpty ? format : ' {device_count}',
      state,
    );

    output = fmt
        .replaceAll('{icon}', icon)
        .replaceAll('{power}', power)
        .replaceAll('{device_count}', '$count')
        .replaceAll('{device}', device)
        .replaceAll('{devices}', devices)
        .replaceAll('{adapter}', _snap.adapterName);

    tooltip = resolveTooltip(
      !powered
          ? 'Bluetooth off'
          : (count == 0 ? 'Bluetooth on · no devices' : 'Connected: $devices'),
      {
        'power': power,
        'device_count': '$count',
        'device': device,
        'devices': devices,
      },
    );

    if (output != _lastOut) {
      _lastOut = output;
      requestRepaint?.call();
    }
  }

  @override
  void onClick(double x, double y, {int button = 0x110}) {
    if (onClickCmd.isNotEmpty) {
      runBarCommand(onClickCmd);
      return;
    }
    // Default: open blueman if available.
    runBarCommand('blueman-manager');
  }
}
