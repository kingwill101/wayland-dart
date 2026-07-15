/// BlueZ D-Bus client (system bus) — replaces `bluetoothctl` polling.
///
/// Uses `org.freedesktop.DBus.ObjectManager` on `org.bluez` for adapters and
/// devices, plus optional PropertiesChanged subscriptions for live updates.
library;

import 'dart:async';

import 'package:dbus/dbus.dart';

class BluezDevice {
  final String path;
  final String address;
  final String name;
  final bool connected;
  final bool paired;
  final String icon;

  const BluezDevice({
    required this.path,
    required this.address,
    required this.name,
    required this.connected,
    required this.paired,
    required this.icon,
  });
}

class BluezSnapshot {
  final bool powered;
  final String adapterName;
  final List<BluezDevice> devices;

  const BluezSnapshot({
    required this.powered,
    required this.adapterName,
    required this.devices,
  });

  List<BluezDevice> get connected =>
      devices.where((d) => d.connected).toList(growable: false);

  int get connectedCount => connected.length;

  /// First connected device name, or empty.
  String get primaryName =>
      connected.isEmpty ? '' : connected.first.name;
}

/// Shared BlueZ watcher. One system-bus connection for the process.
class BluezClient {
  BluezClient._();
  static final BluezClient instance = BluezClient._();

  DBusClient? _bus;
  StreamSubscription<DBusSignal>? _propsSub;
  StreamSubscription<DBusSignal>? _ifAdded;
  StreamSubscription<DBusSignal>? _ifRemoved;
  Timer? _debounce;
  final _listeners = <void Function(BluezSnapshot)>[];
  BluezSnapshot _last = const BluezSnapshot(
    powered: false,
    adapterName: '',
    devices: [],
  );
  bool _started = false;

  BluezSnapshot get last => _last;

  void addListener(void Function(BluezSnapshot) fn) {
    _listeners.add(fn);
    if (!_started) {
      unawaited(_ensureStarted());
    } else {
      fn(_last);
    }
  }

  void removeListener(void Function(BluezSnapshot) fn) {
    _listeners.remove(fn);
  }

  Future<void> _ensureStarted() async {
    if (_started) return;
    _started = true;
    try {
      _bus = DBusClient.system();
      await refresh();
      final bus = _bus!;
      // Any BlueZ property change (adapter powered, device connected, …).
      _propsSub = DBusSignalStream(
        bus,
        sender: 'org.bluez',
        interface: 'org.freedesktop.DBus.Properties',
        name: 'PropertiesChanged',
      ).listen((_) => _scheduleRefresh());

      final om = DBusRemoteObject(
        bus,
        name: 'org.bluez',
        path: DBusObjectPath('/'),
      );
      _ifAdded = DBusRemoteObjectSignalStream(
        object: om,
        interface: 'org.freedesktop.DBus.ObjectManager',
        name: 'InterfacesAdded',
        signature: DBusSignature('oa{sa{sv}}'),
      ).listen((_) => _scheduleRefresh());
      _ifRemoved = DBusRemoteObjectSignalStream(
        object: om,
        interface: 'org.freedesktop.DBus.ObjectManager',
        name: 'InterfacesRemoved',
        signature: DBusSignature('oas'),
      ).listen((_) => _scheduleRefresh());
    } catch (_) {
      _last = const BluezSnapshot(
        powered: false,
        adapterName: '',
        devices: [],
      );
    }
  }

  void _scheduleRefresh() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 80), () {
      unawaited(refresh());
    });
  }

  Future<BluezSnapshot> refresh() async {
    try {
      _bus ??= DBusClient.system();
      final root = DBusRemoteObject(
        _bus!,
        name: 'org.bluez',
        path: DBusObjectPath('/'),
      );
      final result = await root.callMethod(
        'org.freedesktop.DBus.ObjectManager',
        'GetManagedObjects',
        [],
        replySignature: DBusSignature('a{oa{sa{sv}}}'),
      );
      final map = result.returnValues.first as DBusDict;

      var powered = false;
      var adapterName = '';
      final devices = <BluezDevice>[];

      for (final entry in map.children.entries) {
        final path = (entry.key as DBusObjectPath).value;
        final ifaces = entry.value as DBusDict;
        for (final ie in ifaces.children.entries) {
          final iface = (ie.key as DBusString).value;
          final props = ie.value as DBusDict;
          if (iface == 'org.bluez.Adapter1') {
            powered = _bool(props, 'Powered');
            adapterName = _str(props, 'Alias').isNotEmpty
                ? _str(props, 'Alias')
                : _str(props, 'Name');
          } else if (iface == 'org.bluez.Device1') {
            devices.add(
              BluezDevice(
                path: path,
                address: _str(props, 'Address'),
                name: () {
                  final a = _str(props, 'Alias');
                  if (a.isNotEmpty) return a;
                  return _str(props, 'Name');
                }(),
                connected: _bool(props, 'Connected'),
                paired: _bool(props, 'Paired'),
                icon: _str(props, 'Icon'),
              ),
            );
          }
        }
      }

      _last = BluezSnapshot(
        powered: powered,
        adapterName: adapterName,
        devices: devices,
      );
      for (final l in List.of(_listeners)) {
        l(_last);
      }
      return _last;
    } catch (_) {
      _last = const BluezSnapshot(
        powered: false,
        adapterName: '',
        devices: [],
      );
      for (final l in List.of(_listeners)) {
        l(_last);
      }
      return _last;
    }
  }

  static bool _bool(DBusDict props, String key) {
    final v = props.children[DBusString(key)];
    if (v is DBusBoolean) return v.value;
    if (v is DBusVariant && v.value is DBusBoolean) {
      return (v.value as DBusBoolean).value;
    }
    return false;
  }

  static String _str(DBusDict props, String key) {
    final v = props.children[DBusString(key)];
    final inner = v is DBusVariant ? v.value : v;
    if (inner is DBusString) return inner.value;
    return '';
  }

  Future<void> dispose() async {
    await _propsSub?.cancel();
    await _ifAdded?.cancel();
    await _ifRemoved?.cancel();
    _debounce?.cancel();
    await _bus?.close();
    _bus = null;
    _started = false;
  }
}
