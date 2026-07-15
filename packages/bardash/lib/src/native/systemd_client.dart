/// systemd D-Bus client (system bus) — failed unit count without `systemctl`.
library;

import 'dart:async';

import 'package:dbus/dbus.dart';

class SystemdFailedSnapshot {
  final int count;
  final List<String> unitNames;
  final bool available;

  const SystemdFailedSnapshot({
    required this.count,
    required this.unitNames,
    required this.available,
  });

  static const unavailable = SystemdFailedSnapshot(
    count: 0,
    unitNames: [],
    available: false,
  );
}

class SystemdClient {
  SystemdClient._();
  static final SystemdClient instance = SystemdClient._();

  static const _name = 'org.freedesktop.systemd1';
  static const _path = '/org/freedesktop/systemd1';
  static const _iface = 'org.freedesktop.systemd1.Manager';

  DBusClient? _bus;
  final _subs = <StreamSubscription<DBusSignal>>[];
  final _listeners = <void Function(SystemdFailedSnapshot)>[];
  SystemdFailedSnapshot _last = SystemdFailedSnapshot.unavailable;
  bool _started = false;

  SystemdFailedSnapshot get last => _last;

  void addListener(void Function(SystemdFailedSnapshot) fn) {
    _listeners.add(fn);
    if (!_started) {
      unawaited(_ensureStarted());
    } else {
      fn(_last);
    }
  }

  void removeListener(void Function(SystemdFailedSnapshot) fn) {
    _listeners.remove(fn);
  }

  Future<void> _ensureStarted() async {
    if (_started) return;
    _started = true;
    try {
      _bus = DBusClient.system();
      await refresh();
      final mgr = DBusRemoteObject(
        _bus!,
        name: _name,
        path: DBusObjectPath(_path),
      );
      _subs.add(DBusRemoteObjectSignalStream(
        object: mgr,
        interface: 'org.freedesktop.DBus.Properties',
        name: 'PropertiesChanged',
        signature: DBusSignature('sa{sv}as'),
      ).listen((sig) {
        final iface = (sig.values[0] as DBusString).value;
        if (iface == _iface) unawaited(refresh());
      }));
    } catch (_) {
      _emit(SystemdFailedSnapshot.unavailable);
    }
  }

  Future<SystemdFailedSnapshot> refresh() async {
    try {
      _bus ??= DBusClient.system();
      final mgr = DBusRemoteObject(
        _bus!,
        name: _name,
        path: DBusObjectPath(_path),
      );

      var count = 0;
      try {
        final n = await mgr.getProperty(
          _iface,
          'NFailedUnits',
          signature: DBusSignature('u'),
        );
        if (n is DBusUint32) count = n.value;
      } catch (_) {
        // Older systemd without NFailedUnits — fall through to list.
      }

      final names = <String>[];
      try {
        final result = await mgr.callMethod(
          _iface,
          'ListUnitsFiltered',
          [
            DBusArray.string(['failed']),
          ],
          replySignature: DBusSignature('a(ssssssouso)'),
        );
        final arr = result.returnValues.first as DBusArray;
        for (final row in arr.children) {
          if (row is! DBusStruct || row.children.isEmpty) continue;
          final name = row.children[0];
          if (name is DBusString) names.add(name.value);
        }
        if (count == 0 && names.isNotEmpty) count = names.length;
        // Prefer explicit list length when property and list disagree.
        if (names.isNotEmpty) count = names.length;
      } catch (_) {
        // Keep property-only count.
      }

      _emit(SystemdFailedSnapshot(
        count: count,
        unitNames: names,
        available: true,
      ));
      return _last;
    } catch (_) {
      _emit(SystemdFailedSnapshot.unavailable);
      return _last;
    }
  }

  void _emit(SystemdFailedSnapshot s) {
    _last = s;
    for (final fn in List.of(_listeners)) {
      try {
        fn(s);
      } catch (_) {}
    }
  }
}
