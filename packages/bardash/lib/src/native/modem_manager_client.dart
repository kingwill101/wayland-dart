/// ModemManager D-Bus client (system bus) — WWAN without `mmcli`.
library;

import 'dart:async';

import 'package:dbus/dbus.dart';

class ModemSnapshot {
  final bool available;
  final bool hasModem;
  final String state;
  final int signal; // 0–100
  final String operatorName;
  final String technology;
  final String imei;
  final String path;

  const ModemSnapshot({
    required this.available,
    required this.hasModem,
    required this.state,
    required this.signal,
    required this.operatorName,
    required this.technology,
    required this.imei,
    required this.path,
  });

  static const empty = ModemSnapshot(
    available: false,
    hasModem: false,
    state: '',
    signal: 0,
    operatorName: '',
    technology: '',
    imei: '',
    path: '',
  );

  bool get disabled =>
      state.isEmpty ||
      state == 'disabled' ||
      state == 'failed' ||
      state == 'unknown';
}

/// MMModemState (org.freedesktop.ModemManager1.Modem.State).
const _mmStateNames = <int, String>{
  -1: 'failed',
  0: 'unknown',
  1: 'initializing',
  2: 'locked',
  3: 'disabled',
  4: 'disabling',
  5: 'enabling',
  6: 'enabled',
  7: 'searching',
  8: 'registered',
  9: 'disconnecting',
  10: 'connecting',
  11: 'connected',
};

/// Access technology bit flags → short label.
String _techFromFlags(int flags) {
  if (flags == 0) return '';
  // Prefer highest generation.
  if (flags & (1 << 15) != 0) return 'NR5G'; // 5GNR
  if (flags & (1 << 14) != 0) return 'LTE';
  if (flags & (1 << 9) != 0) return 'HSPA+';
  if (flags & (1 << 8) != 0) return 'HSPA';
  if (flags & (1 << 5) != 0) return 'UMTS';
  if (flags & (1 << 3) != 0) return 'EDGE';
  if (flags & (1 << 2) != 0) return 'GPRS';
  if (flags & (1 << 1) != 0) return 'GSM';
  return 'WWAN';
}

class ModemManagerClient {
  ModemManagerClient._();
  static final ModemManagerClient instance = ModemManagerClient._();

  static const _name = 'org.freedesktop.ModemManager1';
  static const _root = '/org/freedesktop/ModemManager1';

  DBusClient? _bus;
  final _subs = <StreamSubscription<DBusSignal>>[];
  final _listeners = <void Function(ModemSnapshot)>[];
  ModemSnapshot _last = ModemSnapshot.empty;
  bool _started = false;
  int _modemIndex = 0;

  ModemSnapshot get last => _last;

  void setModemIndex(int index) {
    _modemIndex = index < 0 ? 0 : index;
  }

  void addListener(void Function(ModemSnapshot) fn) {
    _listeners.add(fn);
    if (!_started) {
      unawaited(_ensureStarted());
    } else {
      fn(_last);
    }
  }

  void removeListener(void Function(ModemSnapshot) fn) {
    _listeners.remove(fn);
  }

  Future<void> _ensureStarted() async {
    if (_started) return;
    _started = true;
    try {
      _bus = DBusClient.system();
      await refresh();
      final root = DBusRemoteObject(
        _bus!,
        name: _name,
        path: DBusObjectPath(_root),
      );
      // ObjectManager signals when modems appear/disappear.
      _subs.add(DBusRemoteObjectSignalStream(
        object: root,
        interface: 'org.freedesktop.DBus.ObjectManager',
        name: 'InterfacesAdded',
        signature: DBusSignature('oa{sa{sv}}'),
      ).listen((_) => unawaited(refresh())));
      _subs.add(DBusRemoteObjectSignalStream(
        object: root,
        interface: 'org.freedesktop.DBus.ObjectManager',
        name: 'InterfacesRemoved',
        signature: DBusSignature('oas'),
      ).listen((_) => unawaited(refresh())));
      // Broad property changes on ModemManager1.*
      _subs.add(DBusSignalStream(
        _bus!,
        sender: _name,
        interface: 'org.freedesktop.DBus.Properties',
        name: 'PropertiesChanged',
      ).listen((_) => unawaited(refresh())));
    } catch (_) {
      _emit(ModemSnapshot.empty);
    }
  }

  Future<ModemSnapshot> refresh() async {
    try {
      _bus ??= DBusClient.system();
      final root = DBusRemoteObject(
        _bus!,
        name: _name,
        path: DBusObjectPath(_root),
      );

      final managed = await root.callMethod(
        'org.freedesktop.DBus.ObjectManager',
        'GetManagedObjects',
        [],
        replySignature: DBusSignature('a{oa{sa{sv}}}'),
      );
      final objects = managed.returnValues.first as DBusDict;
      final modemPaths = <String>[];
      for (final entry in objects.children.entries) {
        final path = entry.key;
        if (path is! DBusObjectPath) continue;
        final ifaces = entry.value;
        if (ifaces is! DBusDict) continue;
        final hasModem = ifaces.children.keys.any(
          (k) => k is DBusString && k.value == 'org.freedesktop.ModemManager1.Modem',
        );
        if (hasModem) modemPaths.add(path.value);
      }
      modemPaths.sort();

      if (modemPaths.isEmpty) {
        _emit(const ModemSnapshot(
          available: true,
          hasModem: false,
          state: '',
          signal: 0,
          operatorName: '',
          technology: '',
          imei: '',
          path: '',
        ));
        return _last;
      }

      final idx = _modemIndex.clamp(0, modemPaths.length - 1);
      final path = modemPaths[idx];
      final modem = DBusRemoteObject(
        _bus!,
        name: _name,
        path: DBusObjectPath(path),
      );
      const iface = 'org.freedesktop.ModemManager1.Modem';
      const gpp = 'org.freedesktop.ModemManager1.Modem.Modem3gpp';

      Future<DBusValue?> prop(String i, String n, String sig) async {
        try {
          return await modem.getProperty(i, n, signature: DBusSignature(sig));
        } catch (_) {
          return null;
        }
      }

      final stateV = await prop(iface, 'State', 'i');
      final stateInt = stateV is DBusInt32 ? stateV.value : 0;
      final state = _mmStateNames[stateInt] ?? 'unknown';

      // SignalQuality is (u b) — percent + recent flag.
      var signal = 0;
      final sq = await prop(iface, 'SignalQuality', '(ub)');
      if (sq is DBusStruct && sq.children.isNotEmpty) {
        final p = sq.children[0];
        if (p is DBusUint32) signal = p.value.clamp(0, 100);
      }

      final techV = await prop(iface, 'AccessTechnologies', 'u');
      final tech = techV is DBusUint32 ? _techFromFlags(techV.value) : '';

      final equip = await prop(iface, 'EquipmentIdentifier', 's');
      final imei = equip is DBusString ? equip.value : '';

      final opV = await prop(gpp, 'OperatorName', 's');
      final operatorName = opV is DBusString ? opV.value : '';

      _emit(ModemSnapshot(
        available: true,
        hasModem: true,
        state: state,
        signal: signal,
        operatorName: operatorName,
        technology: tech,
        imei: imei,
        path: path,
      ));
      return _last;
    } catch (_) {
      _emit(ModemSnapshot.empty);
      return _last;
    }
  }

  void _emit(ModemSnapshot s) {
    _last = s;
    for (final fn in List.of(_listeners)) {
      try {
        fn(s);
      } catch (_) {}
    }
  }
}
