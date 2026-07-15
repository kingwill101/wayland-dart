/// Feral GameMode status — runtime file first, optional session D-Bus.
library;

import 'dart:async';
import 'dart:io';

import 'package:dbus/dbus.dart';

class GamemodeSnapshot {
  final int clientCount;
  final bool available;

  const GamemodeSnapshot({
    required this.clientCount,
    required this.available,
  });

  bool get active => clientCount > 0;

  static const empty = GamemodeSnapshot(clientCount: 0, available: false);
}

class GamemodeClient {
  GamemodeClient._();
  static final GamemodeClient instance = GamemodeClient._();

  final _listeners = <void Function(GamemodeSnapshot)>[];
  GamemodeSnapshot _last = GamemodeSnapshot.empty;
  DBusClient? _bus;
  bool _dbusTried = false;
  bool _dbusOk = false;

  GamemodeSnapshot get last => _last;

  void addListener(void Function(GamemodeSnapshot) fn) {
    _listeners.add(fn);
    fn(_last);
  }

  void removeListener(void Function(GamemodeSnapshot) fn) {
    _listeners.remove(fn);
  }

  Future<GamemodeSnapshot> refresh() async {
    // 1) Runtime client count file (no subprocess).
    final fromFile = _fromRuntimeFile();
    if (fromFile != null) {
      _emit(fromFile);
      return _last;
    }

    // 2) Session D-Bus com.feralinteractive.GameMode
    final fromDbus = await _fromDbus();
    if (fromDbus != null) {
      _emit(fromDbus);
      return _last;
    }

    _emit(GamemodeSnapshot.empty);
    return _last;
  }

  GamemodeSnapshot? _fromRuntimeFile() {
    try {
      final uid = Platform.environment['UID'] ??
          (() {
            try {
              return File('/proc/self/status')
                  .readAsLinesSync()
                  .firstWhere((l) => l.startsWith('Uid:'))
                  .split(RegExp(r'\s+'))[1];
            } catch (_) {
              return '1000';
            }
          })();
      final runtime = Platform.environment['XDG_RUNTIME_DIR'] ??
          '/run/user/$uid';
      final paths = [
        '$runtime/gamemode/client.count',
        '/run/gamemode/client.count',
      ];
      for (final p in paths) {
        final f = File(p);
        if (!f.existsSync()) continue;
        final n = int.tryParse(f.readAsStringSync().trim()) ?? 0;
        return GamemodeSnapshot(clientCount: n, available: true);
      }
    } catch (_) {}
    return null;
  }

  Future<GamemodeSnapshot?> _fromDbus() async {
    if (_dbusTried && !_dbusOk) return null;
    try {
      _bus ??= DBusClient.session();
      _dbusTried = true;
      final obj = DBusRemoteObject(
        _bus!,
        name: 'com.feralinteractive.GameMode',
        path: DBusObjectPath('/com/feralinteractive/GameMode'),
      );
      // ClientCount property when available.
      try {
        final v = await obj.getProperty(
          'com.feralinteractive.GameMode',
          'ClientCount',
          signature: DBusSignature('i'),
        );
        _dbusOk = true;
        final n = v is DBusInt32 ? v.value : 0;
        return GamemodeSnapshot(clientCount: n < 0 ? 0 : n, available: true);
      } catch (_) {
        // Method QueryStatus / similar on older builds.
        try {
          final r = await obj.callMethod(
            'com.feralinteractive.GameMode',
            'QueryStatus',
            [const DBusInt32(0)],
            replySignature: DBusSignature('i'),
          );
          _dbusOk = true;
          final n = r.returnValues.first;
          final status = n is DBusInt32 ? n.value : 0;
          // 0 = inactive, >0 often active client count or boolean 1.
          return GamemodeSnapshot(
            clientCount: status > 0 ? status : 0,
            available: true,
          );
        } catch (_) {
          _dbusOk = false;
          return null;
        }
      }
    } catch (_) {
      _dbusTried = true;
      _dbusOk = false;
      return null;
    }
  }

  void _emit(GamemodeSnapshot s) {
    _last = s;
    for (final fn in List.of(_listeners)) {
      try {
        fn(s);
      } catch (_) {}
    }
  }
}
