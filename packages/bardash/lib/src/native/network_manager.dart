/// NetworkManager D-Bus client (system bus) — primary connection + wifi signal.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dbus/dbus.dart';

class NmSnapshot {
  final bool connected;
  final String type; // wifi | ethernet | other | disconnected
  final String ifname;
  final String ip4;
  final String ssid;
  final int signal; // 0–100, or -1 if N/A
  final String connectionId;

  const NmSnapshot({
    required this.connected,
    required this.type,
    required this.ifname,
    required this.ip4,
    required this.ssid,
    required this.signal,
    required this.connectionId,
  });

  static const disconnected = NmSnapshot(
    connected: false,
    type: 'disconnected',
    ifname: '',
    ip4: '',
    ssid: '',
    signal: -1,
    connectionId: '',
  );
}

class NetworkManagerClient {
  NetworkManagerClient._();
  static final NetworkManagerClient instance = NetworkManagerClient._();

  DBusClient? _bus;
  StreamSubscription<DBusSignal>? _propsSub;
  Timer? _debounce;
  final _listeners = <void Function(NmSnapshot)>[];
  NmSnapshot _last = NmSnapshot.disconnected;
  bool _started = false;

  NmSnapshot get last => _last;

  void addListener(void Function(NmSnapshot) fn) {
    _listeners.add(fn);
    if (!_started) {
      unawaited(_ensureStarted());
    } else {
      fn(_last);
    }
  }

  void removeListener(void Function(NmSnapshot) fn) {
    _listeners.remove(fn);
  }

  Future<void> _ensureStarted() async {
    if (_started) return;
    _started = true;
    try {
      _bus = DBusClient.system();
      await refresh();
      final nm = DBusRemoteObject(
        _bus!,
        name: 'org.freedesktop.NetworkManager',
        path: DBusObjectPath('/org/freedesktop/NetworkManager'),
      );
      _propsSub = DBusRemoteObjectSignalStream(
        object: nm,
        interface: 'org.freedesktop.DBus.Properties',
        name: 'PropertiesChanged',
        signature: DBusSignature('sa{sv}as'),
      ).listen((_) => _scheduleRefresh());
    } catch (_) {
      _last = NmSnapshot.disconnected;
    }
  }

  void _scheduleRefresh() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 120), () {
      unawaited(refresh());
    });
  }

  Future<NmSnapshot> refresh() async {
    try {
      _bus ??= DBusClient.system();
      final nm = DBusRemoteObject(
        _bus!,
        name: 'org.freedesktop.NetworkManager',
        path: DBusObjectPath('/org/freedesktop/NetworkManager'),
      );

      final primaryV = await nm.getProperty(
        'org.freedesktop.NetworkManager',
        'PrimaryConnection',
        signature: DBusSignature('o'),
      );
      final primaryPath =
          primaryV is DBusObjectPath ? primaryV.value : '';
      if (primaryPath.isEmpty || primaryPath == '/') {
        _emit(NmSnapshot.disconnected);
        return _last;
      }

      final conn = DBusRemoteObject(
        _bus!,
        name: 'org.freedesktop.NetworkManager',
        path: DBusObjectPath(primaryPath),
      );
      final typeV = await conn.getProperty(
        'org.freedesktop.NetworkManager.Connection.Active',
        'Type',
        signature: DBusSignature('s'),
      );
      final idV = await conn.getProperty(
        'org.freedesktop.NetworkManager.Connection.Active',
        'Id',
        signature: DBusSignature('s'),
      );
      final devicesV = await conn.getProperty(
        'org.freedesktop.NetworkManager.Connection.Active',
        'Devices',
        signature: DBusSignature('ao'),
      );
      final ip4PathV = await conn.getProperty(
        'org.freedesktop.NetworkManager.Connection.Active',
        'Ip4Config',
        signature: DBusSignature('o'),
      );

      final type = typeV is DBusString ? typeV.value : 'other';
      final id = idV is DBusString ? idV.value : '';
      var ifname = '';
      var ssid = '';
      var signal = -1;

      if (devicesV is DBusArray && devicesV.children.isNotEmpty) {
        final devPath = (devicesV.children.first as DBusObjectPath).value;
        final dev = DBusRemoteObject(
          _bus!,
          name: 'org.freedesktop.NetworkManager',
          path: DBusObjectPath(devPath),
        );
        final ifV = await dev.getProperty(
          'org.freedesktop.NetworkManager.Device',
          'Interface',
          signature: DBusSignature('s'),
        );
        if (ifV is DBusString) ifname = ifV.value;

        // Wifi: ActiveAccessPoint → Ssid + Strength
        if (type.contains('wireless') || type == '802-11-wireless') {
          try {
            final apPathV = await dev.getProperty(
              'org.freedesktop.NetworkManager.Device.Wireless',
              'ActiveAccessPoint',
              signature: DBusSignature('o'),
            );
            final apPath =
                apPathV is DBusObjectPath ? apPathV.value : '';
            if (apPath.isNotEmpty && apPath != '/') {
              final ap = DBusRemoteObject(
                _bus!,
                name: 'org.freedesktop.NetworkManager',
                path: DBusObjectPath(apPath),
              );
              final ssidV = await ap.getProperty(
                'org.freedesktop.NetworkManager.AccessPoint',
                'Ssid',
                signature: DBusSignature('ay'),
              );
              final strV = await ap.getProperty(
                'org.freedesktop.NetworkManager.AccessPoint',
                'Strength',
                signature: DBusSignature('y'),
              );
              ssid = _ssidFrom(ssidV);
              if (strV is DBusByte) signal = strV.value;
              if (strV is DBusVariant && strV.value is DBusByte) {
                signal = (strV.value as DBusByte).value;
              }
            }
          } catch (_) {}
        }
      }

      var ip4 = '';
      final ip4Path =
          ip4PathV is DBusObjectPath ? ip4PathV.value : '';
      if (ip4Path.isNotEmpty && ip4Path != '/') {
        try {
          final ip4obj = DBusRemoteObject(
            _bus!,
            name: 'org.freedesktop.NetworkManager',
            path: DBusObjectPath(ip4Path),
          );
          final addrsV = await ip4obj.getProperty(
            'org.freedesktop.NetworkManager.IP4Config',
            'AddressData',
            signature: DBusSignature('aa{sv}'),
          );
          ip4 = _firstAddress(addrsV);
        } catch (_) {}
      }

      final kind = type.contains('wireless') || type == '802-11-wireless'
          ? 'wifi'
          : (type.contains('ethernet') || type == '802-3-ethernet'
              ? 'ethernet'
              : 'other');

      _emit(
        NmSnapshot(
          connected: true,
          type: kind,
          ifname: ifname,
          ip4: ip4,
          ssid: ssid,
          signal: signal,
          connectionId: id,
        ),
      );
      return _last;
    } catch (_) {
      _emit(NmSnapshot.disconnected);
      return _last;
    }
  }

  void _emit(NmSnapshot s) {
    _last = s;
    for (final l in List.of(_listeners)) {
      l(_last);
    }
  }

  static String _ssidFrom(DBusValue v) {
    final inner = v is DBusVariant ? v.value : v;
    if (inner is! DBusArray) return '';
    try {
      final bytes = Uint8List.fromList(inner.asByteArray().toList());
      return utf8.decode(bytes, allowMalformed: true);
    } catch (_) {
      return '';
    }
  }

  static String _firstAddress(DBusValue v) {
    final inner = v is DBusVariant ? v.value : v;
    if (inner is! DBusArray) return '';
    for (final child in inner.children) {
      if (child is! DBusDict) continue;
      final addr = child.children[DBusString('address')];
      final a = addr is DBusVariant ? addr.value : addr;
      if (a is DBusString && a.value.isNotEmpty) return a.value;
    }
    return '';
  }

  Future<void> dispose() async {
    await _propsSub?.cancel();
    _debounce?.cancel();
    await _bus?.close();
    _bus = null;
    _started = false;
  }
}
