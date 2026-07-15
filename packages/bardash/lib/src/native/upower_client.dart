/// UPower D-Bus client (system bus) — battery/line power without `upower` CLI.
library;

import 'dart:async';

import 'package:dbus/dbus.dart';

/// UPower device state (org.freedesktop.UPower.Device.State).
enum UpDeviceState {
  unknown,
  charging,
  discharging,
  empty,
  fullyCharged,
  pendingCharge,
  pendingDischarge,
}

UpDeviceState _stateFromInt(int v) {
  if (v < 0 || v >= UpDeviceState.values.length) {
    return UpDeviceState.unknown;
  }
  return UpDeviceState.values[v];
}

class UpDeviceSnapshot {
  final String path;
  final String nativePath; // e.g. BAT0
  final String model;
  final double percentage;
  final UpDeviceState state;
  final int timeToEmptySec;
  final int timeToFullSec;
  final bool isPresent;
  final String iconName;
  final bool powerSupply;

  const UpDeviceSnapshot({
    required this.path,
    required this.nativePath,
    required this.model,
    required this.percentage,
    required this.state,
    required this.timeToEmptySec,
    required this.timeToFullSec,
    required this.isPresent,
    required this.iconName,
    required this.powerSupply,
  });

  bool get isCharging =>
      state == UpDeviceState.charging ||
      state == UpDeviceState.pendingCharge;

  bool get isDischarging =>
      state == UpDeviceState.discharging ||
      state == UpDeviceState.pendingDischarge;

  String get stateLabel {
    switch (state) {
      case UpDeviceState.charging:
        return 'Charging';
      case UpDeviceState.discharging:
        return 'Discharging';
      case UpDeviceState.empty:
        return 'Empty';
      case UpDeviceState.fullyCharged:
        return 'Full';
      case UpDeviceState.pendingCharge:
        return 'Pending charge';
      case UpDeviceState.pendingDischarge:
        return 'Pending discharge';
      case UpDeviceState.unknown:
        return 'Unknown';
    }
  }

  /// Human time remaining (empty or full).
  String get timeLabel {
    final sec = isCharging ? timeToFullSec : timeToEmptySec;
    if (sec <= 0 || sec > 86400 * 10) return '';
    final h = sec ~/ 3600;
    final m = (sec % 3600) ~/ 60;
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }
}

class UPowerSnapshot {
  final bool onBattery;
  final bool lidClosed;
  final List<UpDeviceSnapshot> batteries;

  const UPowerSnapshot({
    required this.onBattery,
    required this.lidClosed,
    required this.batteries,
  });

  static const empty = UPowerSnapshot(
    onBattery: false,
    lidClosed: false,
    batteries: [],
  );

  /// Prefer internal power-supply battery (BAT*).
  UpDeviceSnapshot? get primaryBattery {
    if (batteries.isEmpty) return null;
    for (final b in batteries) {
      if (b.powerSupply &&
          (b.nativePath.toUpperCase().startsWith('BAT') ||
              b.path.contains('battery_BAT'))) {
        return b;
      }
    }
    for (final b in batteries) {
      if (b.powerSupply) return b;
    }
    return batteries.first;
  }
}

class UPowerClient {
  UPowerClient._();
  static final UPowerClient instance = UPowerClient._();

  DBusClient? _bus;
  StreamSubscription<DBusSignal>? _propsSub;
  StreamSubscription<DBusSignal>? _added;
  StreamSubscription<DBusSignal>? _removed;
  Timer? _debounce;
  final _listeners = <void Function(UPowerSnapshot)>[];
  UPowerSnapshot _last = UPowerSnapshot.empty;
  bool _started = false;

  UPowerSnapshot get last => _last;

  void addListener(void Function(UPowerSnapshot) fn) {
    _listeners.add(fn);
    if (!_started) {
      unawaited(_ensureStarted());
    } else {
      fn(_last);
    }
  }

  void removeListener(void Function(UPowerSnapshot) fn) {
    _listeners.remove(fn);
  }

  Future<void> _ensureStarted() async {
    if (_started) return;
    _started = true;
    try {
      _bus = DBusClient.system();
      await refresh();
      final bus = _bus!;
      final up = DBusRemoteObject(
        bus,
        name: 'org.freedesktop.UPower',
        path: DBusObjectPath('/org/freedesktop/UPower'),
      );
      _propsSub = DBusSignalStream(
        bus,
        sender: 'org.freedesktop.UPower',
        interface: 'org.freedesktop.DBus.Properties',
        name: 'PropertiesChanged',
      ).listen((_) => _scheduleRefresh());
      _added = DBusRemoteObjectSignalStream(
        object: up,
        interface: 'org.freedesktop.UPower',
        name: 'DeviceAdded',
        signature: DBusSignature('o'),
      ).listen((_) => _scheduleRefresh());
      _removed = DBusRemoteObjectSignalStream(
        object: up,
        interface: 'org.freedesktop.UPower',
        name: 'DeviceRemoved',
        signature: DBusSignature('o'),
      ).listen((_) => _scheduleRefresh());
    } catch (_) {
      _last = UPowerSnapshot.empty;
    }
  }

  void _scheduleRefresh() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 150), () {
      unawaited(refresh());
    });
  }

  Future<UPowerSnapshot> refresh() async {
    try {
      _bus ??= DBusClient.system();
      final up = DBusRemoteObject(
        _bus!,
        name: 'org.freedesktop.UPower',
        path: DBusObjectPath('/org/freedesktop/UPower'),
      );

      var onBattery = false;
      var lidClosed = false;
      try {
        final ob = await up.getProperty(
          'org.freedesktop.UPower',
          'OnBattery',
          signature: DBusSignature('b'),
        );
        if (ob is DBusBoolean) onBattery = ob.value;
      } catch (_) {}
      try {
        final lid = await up.getProperty(
          'org.freedesktop.UPower',
          'LidIsClosed',
          signature: DBusSignature('b'),
        );
        if (lid is DBusBoolean) lidClosed = lid.value;
      } catch (_) {}

      final enumResult = await up.callMethod(
        'org.freedesktop.UPower',
        'EnumerateDevices',
        [],
        replySignature: DBusSignature('ao'),
      );
      final paths = enumResult.returnValues.first as DBusArray;
      final batteries = <UpDeviceSnapshot>[];

      for (final p in paths.children) {
        if (p is! DBusObjectPath) continue;
        final path = p.value;
        // Type 2 = Battery
        final snap = await _readDevice(path);
        if (snap != null && snap.isPresent) {
          // Filter to batteries (Type battery = 2)
          batteries.add(snap);
        }
      }

      // Only keep Type battery if we can detect; Enumerate includes AC lines.
      final onlyBat = batteries
          .where(
            (b) =>
                b.path.contains('battery') ||
                b.nativePath.toUpperCase().startsWith('BAT'),
          )
          .toList();

      _last = UPowerSnapshot(
        onBattery: onBattery,
        lidClosed: lidClosed,
        batteries: onlyBat.isNotEmpty ? onlyBat : batteries,
      );
      for (final l in List.of(_listeners)) {
        l(_last);
      }
      return _last;
    } catch (_) {
      _last = UPowerSnapshot.empty;
      for (final l in List.of(_listeners)) {
        l(_last);
      }
      return _last;
    }
  }

  Future<UpDeviceSnapshot?> _readDevice(String path) async {
    try {
      final dev = DBusRemoteObject(
        _bus!,
        name: 'org.freedesktop.UPower',
        path: DBusObjectPath(path),
      );
      const iface = 'org.freedesktop.UPower.Device';

      Future<DBusValue?> prop(String name, String sig) async {
        try {
          return await dev.getProperty(iface, name, signature: DBusSignature(sig));
        } catch (_) {
          return null;
        }
      }

      final typeV = await prop('Type', 'u');
      final type = typeV is DBusUint32 ? typeV.value : 0;
      // 2 = battery
      if (type != 0 && type != 2) return null;

      final pctV = await prop('Percentage', 'd');
      final stateV = await prop('State', 'u');
      final presentV = await prop('IsPresent', 'b');
      final nativeV = await prop('NativePath', 's');
      final modelV = await prop('Model', 's');
      final emptyV = await prop('TimeToEmpty', 'x');
      final fullV = await prop('TimeToFull', 'x');
      final iconV = await prop('IconName', 's');
      final psV = await prop('PowerSupply', 'b');

      final percentage = pctV is DBusDouble ? pctV.value : 0.0;
      final state = stateV is DBusUint32 ? stateV.value : 0;
      final isPresent = presentV is DBusBoolean ? presentV.value : true;
      if (!isPresent && percentage <= 0) return null;

      return UpDeviceSnapshot(
        path: path,
        nativePath: nativeV is DBusString ? nativeV.value : '',
        model: modelV is DBusString ? modelV.value : '',
        percentage: percentage,
        state: _stateFromInt(state),
        timeToEmptySec: emptyV is DBusInt64
            ? emptyV.value
            : (emptyV is DBusUint64 ? emptyV.value : 0),
        timeToFullSec: fullV is DBusInt64
            ? fullV.value
            : (fullV is DBusUint64 ? fullV.value : 0),
        isPresent: isPresent,
        iconName: iconV is DBusString ? iconV.value : '',
        powerSupply: psV is DBusBoolean ? psV.value : true,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> dispose() async {
    await _propsSub?.cancel();
    await _added?.cancel();
    await _removed?.cancel();
    _debounce?.cancel();
    await _bus?.close();
    _bus = null;
    _started = false;
  }
}
