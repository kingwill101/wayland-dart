/// MPRIS D-Bus client (session bus) — replaces `playerctl` polling.
///
/// Discovers `org.mpris.MediaPlayer2.*` names, reads Player properties, and
/// optionally listens for PropertiesChanged / NameOwnerChanged.
library;

import 'dart:async';

import 'package:dbus/dbus.dart';

class MprisSnapshot {
  final String busName;
  final String status; // Playing | Paused | Stopped
  final String artist;
  final String title;
  final String album;
  final String identity;

  const MprisSnapshot({
    required this.busName,
    required this.status,
    required this.artist,
    required this.title,
    required this.album,
    required this.identity,
  });

  static const empty = MprisSnapshot(
    busName: '',
    status: 'Stopped',
    artist: '',
    title: '',
    album: '',
    identity: '',
  );

  bool get hasTrack => title.isNotEmpty || artist.isNotEmpty;
  bool get isPlaying => status.toLowerCase() == 'playing';
  bool get isPaused => status.toLowerCase() == 'paused';
}

class MprisClient {
  MprisClient._();
  static final MprisClient instance = MprisClient._();

  DBusClient? _bus;
  StreamSubscription<DBusSignal>? _nameSub;
  StreamSubscription<DBusSignal>? _propsSub;
  Timer? _debounce;
  final _listeners = <void Function(MprisSnapshot)>[];
  MprisSnapshot _last = MprisSnapshot.empty;
  String _activeName = '';
  bool _started = false;

  MprisSnapshot get last => _last;

  void addListener(void Function(MprisSnapshot) fn) {
    _listeners.add(fn);
    if (!_started) {
      unawaited(_ensureStarted());
    } else {
      fn(_last);
    }
  }

  void removeListener(void Function(MprisSnapshot) fn) {
    _listeners.remove(fn);
  }

  Future<void> _ensureStarted() async {
    if (_started) return;
    _started = true;
    try {
      _bus = DBusClient.session();
      await refresh();
      final bus = _bus!;
      // New / lost media players.
      _nameSub = DBusSignalStream(
        bus,
        sender: 'org.freedesktop.DBus',
        interface: 'org.freedesktop.DBus',
        name: 'NameOwnerChanged',
        path: DBusObjectPath('/org/freedesktop/DBus'),
        signature: DBusSignature('sss'),
      ).listen((sig) {
        if (sig.values.isEmpty) return;
        final name = (sig.values[0] as DBusString).value;
        if (name.startsWith('org.mpris.MediaPlayer2.')) {
          _scheduleRefresh();
        }
      });
    } catch (_) {
      _last = MprisSnapshot.empty;
    }
  }

  void _scheduleRefresh() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 100), () {
      unawaited(refresh());
    });
  }

  Future<void> _listenPlayer(String busName) async {
    await _propsSub?.cancel();
    _propsSub = null;
    if (busName.isEmpty || _bus == null) return;
    final obj = DBusRemoteObject(
      _bus!,
      name: busName,
      path: DBusObjectPath('/org/mpris/MediaPlayer2'),
    );
    _propsSub = DBusRemoteObjectSignalStream(
      object: obj,
      interface: 'org.freedesktop.DBus.Properties',
      name: 'PropertiesChanged',
      signature: DBusSignature('sa{sv}as'),
    ).listen((_) => _scheduleRefresh());
  }

  Future<MprisSnapshot> refresh() async {
    try {
      _bus ??= DBusClient.session();
      final names = await _bus!.listNames();
      final players = names
          .where((n) => n.startsWith('org.mpris.MediaPlayer2.'))
          .where((n) => !n.endsWith('.playerctld')) // proxy, prefer real players
          .toList();
      // Prefer a Playing player, else first.
      String? chosen;
      MprisSnapshot? best;
      for (final name in players) {
        final snap = await _readPlayer(name);
        if (snap == null) continue;
        best ??= snap;
        chosen ??= name;
        if (snap.isPlaying) {
          best = snap;
          chosen = name;
          break;
        }
      }
      // Fall back to playerctld if nothing else.
      if (best == null && names.contains('org.mpris.MediaPlayer2.playerctld')) {
        best = await _readPlayer('org.mpris.MediaPlayer2.playerctld');
        chosen = 'org.mpris.MediaPlayer2.playerctld';
      }

      _last = best ?? MprisSnapshot.empty;
      if (chosen != null && chosen != _activeName) {
        _activeName = chosen;
        await _listenPlayer(chosen);
      }
      for (final l in List.of(_listeners)) {
        l(_last);
      }
      return _last;
    } catch (_) {
      _last = MprisSnapshot.empty;
      for (final l in List.of(_listeners)) {
        l(_last);
      }
      return _last;
    }
  }

  Future<MprisSnapshot?> _readPlayer(String busName) async {
    try {
      final player = DBusRemoteObject(
        _bus!,
        name: busName,
        path: DBusObjectPath('/org/mpris/MediaPlayer2'),
      );
      final statusV = await player.getProperty(
        'org.mpris.MediaPlayer2.Player',
        'PlaybackStatus',
        signature: DBusSignature('s'),
      );
      final metaV = await player.getProperty(
        'org.mpris.MediaPlayer2.Player',
        'Metadata',
        signature: DBusSignature('a{sv}'),
      );
      var identity = '';
      try {
        final idV = await player.getProperty(
          'org.mpris.MediaPlayer2',
          'Identity',
          signature: DBusSignature('s'),
        );
        if (idV is DBusString) identity = idV.value;
      } catch (_) {}

      final status =
          statusV is DBusString ? statusV.value : statusV.toString();
      final meta = metaV is DBusDict ? metaV : null;
      final artist = _metaArtists(meta);
      final title = _metaStr(meta, 'xesam:title');
      final album = _metaStr(meta, 'xesam:album');
      return MprisSnapshot(
        busName: busName,
        status: status,
        artist: artist,
        title: title,
        album: album,
        identity: identity,
      );
    } catch (_) {
      return null;
    }
  }

  static String _metaStr(DBusDict? meta, String key) {
    if (meta == null) return '';
    final v = meta.children[DBusString(key)];
    final inner = v is DBusVariant ? v.value : v;
    if (inner is DBusString) return inner.value;
    return '';
  }

  static String _metaArtists(DBusDict? meta) {
    if (meta == null) return '';
    final v = meta.children[DBusString('xesam:artist')];
    final inner = v is DBusVariant ? v.value : v;
    if (inner is DBusArray) {
      final parts = <String>[];
      for (final c in inner.children) {
        if (c is DBusString && c.value.isNotEmpty) parts.add(c.value);
      }
      return parts.join(', ');
    }
    if (inner is DBusString) return inner.value;
    return '';
  }

  Future<void> playPause() => _call('PlayPause');
  Future<void> next() => _call('Next');
  Future<void> previous() => _call('Previous');

  Future<void> _call(String method) async {
    final name = _activeName.isNotEmpty ? _activeName : _last.busName;
    if (name.isEmpty || _bus == null) return;
    try {
      final player = DBusRemoteObject(
        _bus!,
        name: name,
        path: DBusObjectPath('/org/mpris/MediaPlayer2'),
      );
      await player.callMethod(
        'org.mpris.MediaPlayer2.Player',
        method,
        [],
      );
      _scheduleRefresh();
    } catch (_) {}
  }

  Future<void> dispose() async {
    await _nameSub?.cancel();
    await _propsSub?.cancel();
    _debounce?.cancel();
    await _bus?.close();
    _bus = null;
    _started = false;
  }
}
