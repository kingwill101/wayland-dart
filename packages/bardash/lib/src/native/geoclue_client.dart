/// GeoClue2 D-Bus client (system bus) — location without `gpspipe`.
///
/// Creates a client, starts it, reads `Location` properties.
/// Falls back gracefully when GeoClue is missing or location is denied.
library;

import 'dart:async';

import 'package:dbus/dbus.dart';

class GeoSnapshot {
  final bool available;
  final bool hasFix;
  final double lat;
  final double lon;
  final double altitude;
  final double speedMps;
  final double accuracy;
  final String description;

  const GeoSnapshot({
    required this.available,
    required this.hasFix,
    required this.lat,
    required this.lon,
    required this.altitude,
    required this.speedMps,
    required this.accuracy,
    required this.description,
  });

  static const empty = GeoSnapshot(
    available: false,
    hasFix: false,
    lat: 0,
    lon: 0,
    altitude: 0,
    speedMps: 0,
    accuracy: 0,
    description: '',
  );

  double get speedKmh => speedMps * 3.6;
}

class GeoclueClient {
  GeoclueClient._();
  static final GeoclueClient instance = GeoclueClient._();

  static const _mgrName = 'org.freedesktop.GeoClue2';
  static const _mgrPath = '/org/freedesktop/GeoClue2/Manager';
  static const _mgrIface = 'org.freedesktop.GeoClue2.Manager';
  static const _clientIface = 'org.freedesktop.GeoClue2.Client';
  static const _locIface = 'org.freedesktop.GeoClue2.Location';

  DBusClient? _bus;
  String? _clientPath;
  final _subs = <StreamSubscription<DBusSignal>>[];
  final _listeners = <void Function(GeoSnapshot)>[];
  GeoSnapshot _last = GeoSnapshot.empty;
  bool _started = false;

  GeoSnapshot get last => _last;

  void addListener(void Function(GeoSnapshot) fn) {
    _listeners.add(fn);
    if (!_started) {
      unawaited(_ensureStarted());
    } else {
      fn(_last);
    }
  }

  void removeListener(void Function(GeoSnapshot) fn) {
    _listeners.remove(fn);
  }

  Future<void> _ensureStarted() async {
    if (_started) return;
    _started = true;
    try {
      _bus = DBusClient.system();
      final mgr = DBusRemoteObject(
        _bus!,
        name: _mgrName,
        path: DBusObjectPath(_mgrPath),
      );
      final created = await mgr.callMethod(
        _mgrIface,
        'GetClient',
        [],
        replySignature: DBusSignature('o'),
      );
      final pathV = created.returnValues.first;
      if (pathV is DBusObjectPath) {
        _clientPath = pathV.value;
      } else if (pathV is DBusString) {
        _clientPath = pathV.value;
      } else {
        throw StateError('unexpected GetClient path: $pathV');
      }

      final client = DBusRemoteObject(
        _bus!,
        name: _mgrName,
        path: DBusObjectPath(_clientPath!),
      );

      // Desktop id helps agents allow bardash.
      await client.setProperty(
        _clientIface,
        'DesktopId',
        const DBusString('bardash'),
      );
      // AccuracyLevel: 4 = Exact (GPS-class); 8 is city — use 4 when available.
      try {
        await client.setProperty(
          _clientIface,
          'RequestedAccuracyLevel',
          const DBusUint32(8), // Exact
        );
      } catch (_) {
        try {
          await client.setProperty(
            _clientIface,
            'RequestedAccuracyLevel',
            const DBusUint32(4), // Street
          );
        } catch (_) {}
      }

      await client.callMethod(_clientIface, 'Start', []);

      _subs.add(DBusRemoteObjectSignalStream(
        object: client,
        interface: _clientIface,
        name: 'LocationUpdated',
        signature: DBusSignature('oo'),
      ).listen((_) => unawaited(refresh())));

      await refresh();
    } catch (_) {
      _emit(GeoSnapshot.empty);
    }
  }

  Future<GeoSnapshot> refresh() async {
    try {
      _bus ??= DBusClient.system();
      if (_clientPath == null) {
        await _ensureStarted();
        if (_clientPath == null) {
          _emit(GeoSnapshot.empty);
          return _last;
        }
      }
      final client = DBusRemoteObject(
        _bus!,
        name: _mgrName,
        path: DBusObjectPath(_clientPath!),
      );
      final locPathV = await client.getProperty(
        _clientIface,
        'Location',
        signature: DBusSignature('o'),
      );
      final locPath =
          locPathV is DBusObjectPath ? locPathV.value : '';
      if (locPath.isEmpty || locPath == '/') {
        _emit(const GeoSnapshot(
          available: true,
          hasFix: false,
          lat: 0,
          lon: 0,
          altitude: 0,
          speedMps: 0,
          accuracy: 0,
          description: '',
        ));
        return _last;
      }

      final loc = DBusRemoteObject(
        _bus!,
        name: _mgrName,
        path: DBusObjectPath(locPath),
      );

      Future<double> d(String name) async {
        try {
          final v = await loc.getProperty(
            _locIface,
            name,
            signature: DBusSignature('d'),
          );
          return v is DBusDouble ? v.value : 0;
        } catch (_) {
          return 0;
        }
      }

      Future<String> s(String name) async {
        try {
          final v = await loc.getProperty(
            _locIface,
            name,
            signature: DBusSignature('s'),
          );
          return v is DBusString ? v.value : '';
        } catch (_) {
          return '';
        }
      }

      final lat = await d('Latitude');
      final lon = await d('Longitude');
      final alt = await d('Altitude');
      final speed = await d('Speed');
      final accuracy = await d('Accuracy');
      final desc = await s('Description');

      final hasFix = lat != 0 || lon != 0;
      _emit(GeoSnapshot(
        available: true,
        hasFix: hasFix,
        lat: lat,
        lon: lon,
        altitude: alt,
        speedMps: speed >= 0 ? speed : 0,
        accuracy: accuracy,
        description: desc,
      ));
      return _last;
    } catch (_) {
      _emit(GeoSnapshot.empty);
      return _last;
    }
  }

  void _emit(GeoSnapshot s) {
    _last = s;
    for (final fn in List.of(_listeners)) {
      try {
        fn(s);
      } catch (_) {}
    }
  }
}
