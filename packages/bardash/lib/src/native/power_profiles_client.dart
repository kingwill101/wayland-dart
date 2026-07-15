/// power-profiles-daemon D-Bus client (when installed).
///
/// Tries common well-known names:
/// - `org.freedesktop.UPower.PowerProfiles` (newer)
/// - `net.hadess.PowerProfiles` (classic)
library;

import 'dart:async';

import 'package:dbus/dbus.dart';

class PowerProfilesSnapshot {
  final String active;
  final List<String> profiles;
  final bool available;

  const PowerProfilesSnapshot({
    required this.active,
    required this.profiles,
    required this.available,
  });

  static const unavailable = PowerProfilesSnapshot(
    active: '',
    profiles: [],
    available: false,
  );
}

class PowerProfilesClient {
  PowerProfilesClient._();
  static final PowerProfilesClient instance = PowerProfilesClient._();

  static const _candidates = <({String name, String path, String iface})>[
    (
      name: 'org.freedesktop.UPower.PowerProfiles',
      path: '/org/freedesktop/UPower/PowerProfiles',
      iface: 'org.freedesktop.UPower.PowerProfiles',
    ),
    (
      name: 'net.hadess.PowerProfiles',
      path: '/net/hadess/PowerProfiles',
      iface: 'net.hadess.PowerProfiles',
    ),
  ];

  DBusClient? _bus;
  StreamSubscription<DBusSignal>? _propsSub;
  Timer? _debounce;
  final _listeners = <void Function(PowerProfilesSnapshot)>[];
  PowerProfilesSnapshot _last = PowerProfilesSnapshot.unavailable;
  String? _serviceName;
  String? _objectPath;
  String? _iface;
  bool _started = false;

  PowerProfilesSnapshot get last => _last;

  void addListener(void Function(PowerProfilesSnapshot) fn) {
    _listeners.add(fn);
    if (!_started) {
      unawaited(_ensureStarted());
    } else {
      fn(_last);
    }
  }

  void removeListener(void Function(PowerProfilesSnapshot) fn) {
    _listeners.remove(fn);
  }

  Future<void> _ensureStarted() async {
    if (_started) return;
    _started = true;
    try {
      _bus = DBusClient.system();
      await refresh();
      if (_serviceName != null && _objectPath != null) {
        final obj = DBusRemoteObject(
          _bus!,
          name: _serviceName!,
          path: DBusObjectPath(_objectPath!),
        );
        _propsSub = DBusRemoteObjectSignalStream(
          object: obj,
          interface: 'org.freedesktop.DBus.Properties',
          name: 'PropertiesChanged',
          signature: DBusSignature('sa{sv}as'),
        ).listen((_) => _scheduleRefresh());
      }
    } catch (_) {
      _last = PowerProfilesSnapshot.unavailable;
    }
  }

  void _scheduleRefresh() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 100), () {
      unawaited(refresh());
    });
  }

  Future<PowerProfilesSnapshot> refresh() async {
    try {
      _bus ??= DBusClient.system();
      for (final c in _candidates) {
        try {
          final obj = DBusRemoteObject(
            _bus!,
            name: c.name,
            path: DBusObjectPath(c.path),
          );
          final activeV = await obj.getProperty(
            c.iface,
            'ActiveProfile',
            signature: DBusSignature('s'),
          );
          final profilesV = await obj.getProperty(
            c.iface,
            'Profiles',
            signature: DBusSignature('aa{sv}'),
          );
          final active =
              activeV is DBusString ? activeV.value : activeV.toString();
          final profiles = <String>[];
          if (profilesV is DBusArray) {
            for (final row in profilesV.children) {
              if (row is! DBusDict) continue;
              final pv = row.children[DBusString('Profile')];
              final inner = pv is DBusVariant ? pv.value : pv;
              if (inner is DBusString) profiles.add(inner.value);
            }
          }
          _serviceName = c.name;
          _objectPath = c.path;
          _iface = c.iface;
          _emit(
            PowerProfilesSnapshot(
              active: active,
              profiles: profiles,
              available: true,
            ),
          );
          return _last;
        } catch (_) {
          continue;
        }
      }
      _emit(PowerProfilesSnapshot.unavailable);
      return _last;
    } catch (_) {
      _emit(PowerProfilesSnapshot.unavailable);
      return _last;
    }
  }

  Future<void> setProfile(String profile) async {
    if (_serviceName == null || _objectPath == null || _iface == null) {
      await refresh();
    }
    if (_serviceName == null || _objectPath == null || _iface == null) return;
    try {
      final obj = DBusRemoteObject(
        _bus!,
        name: _serviceName!,
        path: DBusObjectPath(_objectPath!),
      );
      await obj.setProperty(
        _iface!,
        'ActiveProfile',
        DBusString(profile),
      );
      _scheduleRefresh();
    } catch (_) {}
  }

  /// Cycle to the next profile in the daemon's list.
  Future<void> cycleNext() async {
    final s = _last.available ? _last : await refresh();
    if (!s.available || s.profiles.isEmpty) return;
    final i = s.profiles.indexOf(s.active);
    final next = s.profiles[(i < 0 ? 0 : i + 1) % s.profiles.length];
    await setProfile(next);
  }

  void _emit(PowerProfilesSnapshot s) {
    _last = s;
    for (final l in List.of(_listeners)) {
      l(_last);
    }
  }

  Future<void> dispose() async {
    await _propsSub?.cancel();
    _debounce?.cancel();
    await _bus?.close();
    _bus = null;
    _started = false;
  }
}
