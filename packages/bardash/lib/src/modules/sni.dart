import 'dart:async' as async;
import 'dart:io';
import 'dart:typed_data';

import 'package:dbus/dbus.dart';
import 'package:wayland/wayland.dart';
import 'package:window_toolkit/window_toolkit.dart';

import '../metrics.dart';
import '../native/icon_shim.dart';
import '../png_encode.dart';
import '../tray_menu.dart';
import 'module.dart';

// ── Icon theme (GTK-aligned) ──────────────────────────────────────

/// Parse an `index.theme` file to extract Inherits and subdirectory specs.
Map<String, List<String>> _parseIndexTheme(String path) {
  final result = <String, List<String>>{};
  try {
    final lines = File(path).readAsStringSync().split('\n');
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.startsWith('[') && trimmed.endsWith(']')) continue;
      if (trimmed.startsWith('Inherits=')) {
        result['Inherits'] = trimmed.substring(9).split(',').map((s) => s.trim()).toList();
      } else if (trimmed.startsWith('Directories=')) {
        result['Directories'] = trimmed.substring(12).split(',').map((s) => s.trim()).toList();
      }
    }
  } catch (_) {}
  return result;
}

/// Build the theme search chain starting from [themeName].
/// Returns directories in order: theme subdirs, then inherited theme subdirs.
List<String> _buildThemeDirs(String themeName) {
  final visited = <String>{};
  final dirs = <String>[];
  final queue = [themeName];

  while (queue.isNotEmpty) {
    final name = queue.removeAt(0);
    if (!visited.add(name)) continue;
    final themeDir = '/usr/share/icons/$name';
    if (!Directory(themeDir).existsSync()) continue;

    final info = _parseIndexTheme('$themeDir/index.theme');
    // Add this theme's subdirectories
    final subdirs = info['Directories'] ?? [];
    for (final sub in subdirs) {
      dirs.add('$themeDir/$sub');
    }
    // Enqueue parents
    final inherits = info['Inherits'] ?? [];
    queue.addAll(inherits.reversed); // parent themes first
  }

  return dirs;
}

/// Search [themeDirs] to find an icon file matching [name].
/// Tries multiple sizes (24,32,48,64,22,16, scalable), extensions (png,svg,xpm).
/// Also falls back to hicolor and Adwaita if primary theme misses (sway does this).
String? _findIconInDirs(List<String> themeDirs, String name) {
  if (name.isEmpty) return null;
  final sizes = [24, 32, 48, 64, 22, 16];
  final exts = ['png', 'svg', 'xpm'];

  String? search(List<String> dirs) {
    for (final dir in dirs) {
      final segments = dir.split('/');
      final sizePart = segments.length >= 2 ? segments[segments.length - 2] : '';
      final isScalable = sizePart == 'scalable';
      if (isScalable) {
        for (final ext in exts.where((e) => e != 'xpm')) {
          final path = '$dir/$name.$ext';
          if (File(path).existsSync()) return path;
        }
      } else {
        for (final s in sizes) {
          if (sizePart == '${s}x$s') {
            for (final ext in exts) {
              final path = '$dir/$name.$ext';
              if (File(path).existsSync()) return path;
            }
          }
        }
      }
    }
    return null;
  }

  var found = search(themeDirs);
  if (found != null) return found;
  // Fallback to hicolor/Adwaita/breeze/Papirus like swaybar does when theme icon missing (bluetooth often only in hicolor/papirus)
  for (final fb in ['Papirus', 'hicolor', 'Adwaita', 'breeze', 'breeze-dark']) {
    if (themeDirs.any((d) => d.contains('/$fb/'))) continue;
    final fbDirs = _buildThemeDirs(fb);
    found = search(fbDirs);
    if (found != null) return found;
  }
  return null;
}

/// Generate icon name variants for lookup.
List<String> _iconNameVariants(String name) {
  final set = <String>{name};
  // Strip known suffixes sequentially
  var s = name;
  for (final suf in ['-symbolic', '-regular', '-rtl', '-tray', '.tray']) {
    if (s.endsWith(suf)) {
      s = s.substring(0, s.length - suf.length);
      set.add(s);
    }
  }
  // Strip dotted domain prefix (e.g. "org.cryptomator.Cryptomator" → "Cryptomator")
  final dot = s.lastIndexOf('.');
  if (dot > 0 && dot < s.length - 1) {
    final short = s.substring(dot + 1);
    set.add(short);
    set.add(short.toLowerCase());
  }
  return set.toList();
}

// ── Tray item ──────────────────────────────────────────────────────

class _TrayItem {
  final String busName;
  final String objectPath;
  String iconName = '';
  String attentionIconName = '';
  String title = '';
  String id = '';
  String status = 'Active';
  String? iconThemePath;

  /// Scaled icon size (content of [pixmapPath] / [pixmapData]).
  int pixmapW = 0, pixmapH = 0;
  /// Optional raw RGBA kept only as fallback if PNG write fails.
  Uint8List? pixmapData;
  /// Cached PNG on disk for [Painter.drawImage] (fast path).
  String? pixmapPath;

  /// Cached themed icon path; invalidated when names change.
  String? _themedPath;
  String _themedKey = '';
  bool _themedMiss = false;

  /// Active D-Bus signal subscriptions for this item.
  final List<async.StreamSubscription> _subs = [];
  int _iconGen = 0;

  _TrayItem(this.busName, this.objectPath);

  String get key => '$busName$objectPath';

  bool get isElectronLike =>
      id.startsWith('chrome_status_icon') ||
      id.startsWith('electron_') ||
      iconName.isEmpty;

  Future<void> _getProp(DBusRemoteObject obj, String prop,
      void Function(DBusValue) onValue) async {
    try {
      final val = await obj.getProperty('org.kde.StatusNotifierItem', prop);
      onValue(val);
    } catch (_) {}
  }

  /// DBus menu object path (com.canonical.dbusmenu), if exported.
  String menuPath = '';
  bool itemIsMenu = false;

  Future<void> loadProperties(DBusClient bus) async {
    final obj = DBusRemoteObject(bus,
        name: busName, path: DBusObjectPath(objectPath));

    await _getProp(obj, 'IconName', (v) {
      if (v is DBusString) iconName = v.value;
    });
    await _getProp(obj, 'AttentionIconName', (v) {
      if (v is DBusString) attentionIconName = v.value;
    });
    await _getProp(obj, 'IconThemePath', (v) {
      if (v is DBusString) iconThemePath = v.value;
    });
    await _getProp(obj, 'Title', (v) {
      if (v is DBusString && v.value.isNotEmpty) title = v.value;
    });
    await _getProp(obj, 'Id', (v) {
      if (v is DBusString) id = v.value;
    });
    await _getProp(obj, 'Status', (v) {
      if (v is DBusString) status = v.value;
    });
    await _getProp(obj, 'Menu', (v) {
      if (v is DBusObjectPath) menuPath = v.value;
      if (v is DBusString) menuPath = v.value;
    });
    await _getProp(obj, 'ItemIsMenu', (v) {
      if (v is DBusBoolean) itemIsMenu = v.value;
    });
    // ToolTip struct: (icon_name, pixmap, title, description)
    // 1Password etc. leave Title empty and put the name here.
    await _getProp(obj, 'ToolTip', (v) {
      if (v is DBusStruct && v.children.length >= 3) {
        final t = v.children[2];
        if (t is DBusString && t.value.isNotEmpty) title = t.value;
      }
    });
    _invalidateThemedCache();
  }

  void _invalidateThemedCache() {
    _themedPath = null;
    _themedKey = '';
    _themedMiss = false;
  }

  /// Load IconPixmap (and AttentionIconPixmap when NeedsAttention).
  ///
  /// SNI pixels are **ARGB32 network byte order** (A,R,G,B). We convert to
  /// RGBA, downscale, write a PNG for [drawImage], and drop large D-Bus
  /// arrays so they can be GC'd.
  Future<void> loadPixmap(DBusClient bus, {int targetSize = 32}) async {
    final obj = DBusRemoteObject(bus,
        name: busName, path: DBusObjectPath(objectPath));

    final preferAttention = status == 'NeedsAttention';
    final props = preferAttention
        ? const ['AttentionIconPixmap', 'IconPixmap']
        : const ['IconPixmap', 'AttentionIconPixmap'];

    for (final prop in props) {
      try {
        final result =
            await obj.getProperty('org.kde.StatusNotifierItem', prop);
        final decoded = _decodePixmapArray(result, targetSize);
        // Drop DBus tree ASAP (can be 256k DBusByte objects).
        if (decoded != null) {
          pixmapW = decoded.$1;
          pixmapH = decoded.$2;
          final rgba = decoded.$3;
          // Always keep raw RGBA for reliable pixel draw (PNG is optional).
          pixmapData = rgba;
          _writePixmapPng(rgba);
          return;
        }
      } catch (_) {}
    }
  }

  void _writePixmapPng(Uint8List rgba) {
    try {
      Directory('/tmp/bardash_icons').createSync(recursive: true);
      final path =
          '/tmp/bardash_icons/sni_${busName.hashCode}_${objectPath.hashCode}_$pixmapW.png';
      File(path).writeAsBytesSync(encodeRgbaPng(pixmapW, pixmapH, rgba));
      pixmapPath = path;
    } catch (e) {
      stderr.writeln('[sni] png write failed: $e');
      pixmapPath = null;
    }
  }

  /// Returns (w, h, rgbaBytes) or null.
  static (int, int, Uint8List)? _decodePixmapArray(
    DBusValue result,
    int targetSize,
  ) {
    if (result is! DBusArray) return null;

    // Prefer the largest variant (usually sharpest source).
    DBusStruct? best;
    var bestArea = -1;
    for (final v in result.children) {
      if (v is! DBusStruct || v.children.length < 3) continue;
      final w = _asInt(v.children[0]);
      final h = _asInt(v.children[1]);
      if (w <= 0 || h <= 0) continue;
      final area = w * h;
      if (area > bestArea) {
        bestArea = area;
        best = v;
      }
    }
    if (best == null) return null;

    final srcW = _asInt(best.children[0]);
    final srcH = _asInt(best.children[1]);
    final raw = _asBytes(best.children[2]);
    if (raw == null || raw.length < srcW * srcH * 4) return null;

    // Convert ARGB (network) → RGBA and scale to targetSize.
    final dst = targetSize.clamp(8, 64);
    final out = Uint8List(dst * dst * 4);
    for (var dy = 0; dy < dst; dy++) {
      final sy = (dy * srcH) ~/ dst;
      for (var dx = 0; dx < dst; dx++) {
        final sx = (dx * srcW) ~/ dst;
        final si = (sy * srcW + sx) * 4;
        final di = (dy * dst + dx) * 4;
        final a = raw[si];
        final r = raw[si + 1];
        final g = raw[si + 2];
        final b = raw[si + 3];
        out[di] = r;
        out[di + 1] = g;
        out[di + 2] = b;
        out[di + 3] = a;
      }
    }
    return (dst, dst, out);
  }

  static int _asInt(DBusValue v) {
    if (v is DBusInt32) return v.value;
    if (v is DBusUint32) return v.value;
    if (v is DBusInt16) return v.value;
    if (v is DBusUint16) return v.value;
    return 0;
  }

  /// Prefer bulk `ay` decode — never build a growable list of [DBusByte].
  static Uint8List? _asBytes(DBusValue v) {
    if (v is! DBusArray) return null;
    try {
      // mapByte iterates internal storage without extra DBusByte wrappers
      // when the array was already materialized; still O(n) but one buffer.
      final iter = v.asByteArray();
      if (iter is Uint8List) return iter;
      return Uint8List.fromList(iter.toList(growable: false));
    } catch (_) {
      return null;
    }
  }

  /// Reload icons without blanking the current pixmap (avoids flash).
  Future<void> refreshIcons(DBusClient bus) async {
    final gen = ++_iconGen;
    await loadProperties(bus);
    if (gen != _iconGen) return;

    // Always try pixmap for Electron/1Password; themed first for normal SNIs.
    final themed = findThemedIcon();
    if (themed == null || isElectronLike) {
      await loadPixmap(bus);
    }
  }

  /// Subscribe to SNI change signals so icons/titles refresh live.
  void listenForChanges(DBusClient bus, void Function() onChanged) {
    cancelListeners();
    const iface = 'org.kde.StatusNotifierItem';
    final path = DBusObjectPath(objectPath);

    Future<void> refreshIcon() async {
      await refreshIcons(bus);
      onChanged();
    }

    Future<void> refreshProps() async {
      await loadProperties(bus);
      onChanged();
    }

    void sub(String name, Future<void> Function() handler) {
      final stream = DBusSignalStream(
        bus,
        sender: busName,
        interface: iface,
        name: name,
        path: path,
      );
      _subs.add(stream.listen((_) {
        handler().catchError((e) {
          stderr.writeln('[sni] $name on $busName: $e');
        });
      }));
    }

    sub('NewIcon', refreshIcon);
    sub('NewAttentionIcon', refreshIcon);
    sub('NewOverlayIcon', refreshIcon);
    sub('NewTitle', refreshProps);
    sub('NewToolTip', refreshProps);
    sub('NewStatus', refreshIcon); // status can switch Active ↔ NeedsAttention
    sub('NewIconThemePath', refreshIcon);
    sub('NewMenu', refreshProps);

    // Debounce PropertiesChanged — Electron apps can spam this.
    // Only reload icons when icon-related properties change.
    async.Timer? propDebounce;
    final obj = DBusRemoteObject(bus, name: busName, path: path);
    _subs.add(obj.propertiesChanged.listen((sig) {
      if (sig.propertiesInterface.isNotEmpty &&
          sig.propertiesInterface != iface) {
        return;
      }
      final keys = sig.changedProperties.keys;
      final iconRelated = keys.any((k) =>
          k.contains('Icon') ||
          k.contains('Status') ||
          k.contains('Title') ||
          k.contains('ToolTip'));
      // Empty changed set + invalidated list still means "reload".
      final invalidated = sig.invalidatedProperties;
      final invIcon = invalidated.any((k) =>
          k.contains('Icon') || k.contains('Status') || k.contains('ToolTip'));
      if (!iconRelated && !invIcon && keys.isNotEmpty) {
        return;
      }
      propDebounce?.cancel();
      propDebounce = async.Timer(const Duration(milliseconds: 120), () {
        refreshIcon().catchError((e) {
          stderr.writeln('[sni] PropertiesChanged on $busName: $e');
        });
      });
    }));
  }

  void cancelListeners() {
    for (final s in _subs) {
      s.cancel();
    }
    _subs.clear();
  }

  /// Detect the active icon theme from the environment.
  static String _activeTheme() {
    // Prefer gsettings icon-theme (Papirus-Dark etc), fallback to common dirs.
    try {
      final r = Process.runSync('gsettings', ['get', 'org.gnome.desktop.interface', 'icon-theme'], runInShell: true);
      if (r.exitCode == 0) {
        var v = r.stdout.toString().trim();
        // gsettings returns quoted 'Papirus-Dark'
        if ((v.startsWith("'") && v.endsWith("'")) || (v.startsWith('"') && v.endsWith('"'))) {
          v = v.substring(1, v.length - 1);
        }
        if (v.isNotEmpty && Directory('/usr/share/icons/$v').existsSync()) return v;
        // Try without -Dark suffix
        final base = v.replaceAll(RegExp(r'-Dark$'), '');
        if (base != v && Directory('/usr/share/icons/$base').existsSync()) return base;
      }
    } catch (_) {}
    // GTK settings.ini fallback
    try {
      for (final p in [Platform.environment['HOME']! + '/.config/gtk-3.0/settings.ini', '/etc/gtk-3.0/settings.ini']) {
        final f = File(p);
        if (!f.existsSync()) continue;
        for (final line in f.readAsLinesSync()) {
          final m = RegExp(r'gtk-icon-theme-name\s*=\s*(.+)').firstMatch(line);
          if (m != null) {
            var v = m.group(1)!.trim().replaceAll('"', '').replaceAll("'", '');
            if (v.isNotEmpty && Directory('/usr/share/icons/$v').existsSync()) return v;
          }
        }
      }
    } catch (_) {}
    for (final t in ['Papirus-Dark', 'Papirus', 'Pop', 'Adwaita', 'hicolor']) {
      if (Directory('/usr/share/icons/$t').existsSync()) return t;
    }
    return 'hicolor';
  }

  /// Cached theme directory list — built once from the active theme.
  static List<String>? _cachedThemeDirs;
  static List<String> get _themeDirs {
    if (_cachedThemeDirs != null) return _cachedThemeDirs!;
    _cachedThemeDirs = _buildThemeDirs(_activeTheme());
    return _cachedThemeDirs!;
  }

  static final Map<String, String> _svgCache = {};

  /// Find an icon file. Cached — safe to call every paint.
  ///
  /// Native GTK + librsvg via icon_shim when available; else fallback to
  /// manual _findIconInDirs + rsvg-convert subprocess.
  String? findThemedIcon() {
    final nameForStatus = status == 'NeedsAttention' && attentionIconName.isNotEmpty
        ? attentionIconName
        : iconName;
    final key = '$nameForStatus|$id|$title|$iconThemePath|$status';
    if (_themedKey == key) {
      return _themedMiss ? null : _themedPath;
    }
    _themedKey = key;

    final candidates = <String>[];
    if (nameForStatus.isNotEmpty) candidates.add(nameForStatus);
    // Waybar hack: Electron apps often have no IconName — try title as theme name.
    if (candidates.isEmpty || nameForStatus.isEmpty) {
      if (isElectronLike && title.isNotEmpty) {
        candidates.add(title.toLowerCase());
        candidates.add(title.replaceAll(' ', '-').toLowerCase());
        candidates.add(title.replaceAll(' ', '').toLowerCase());
      }
      // Skip useless chrome_status_icon_* id for theme lookup.
      if (id.isNotEmpty &&
          !id.startsWith('chrome_status_icon') &&
          !id.startsWith('electron_')) {
        candidates.add(id);
      }
    }
    if (candidates.isEmpty) {
      _themedMiss = true;
      _themedPath = null;
      return null;
    }

    final searchDirs = [..._themeDirs];
    if (iconThemePath != null &&
        iconThemePath!.isNotEmpty &&
        Directory(iconThemePath!).existsSync()) {
      searchDirs.insertAll(0, _buildThemeDirs(iconThemePath!));
    }

    for (final name in candidates) {
      for (final variant in _iconNameVariants(name)) {
        // 1) Try native GTK icon theme (handles Inherits, scalable, @2x)
        if (IconShim.isAvailable) {
          final native = IconShim.lookup(variant, size: 32, theme: _TrayItem._activeTheme());
          if (native != null) {
            if (native.endsWith('.svg')) {
              final cached = _svgCache[native];
              if (cached != null && File(cached).existsSync()) {
                _themedPath = cached;
                _themedMiss = false;
                return cached;
              }
              final pngPath = '/tmp/bardash_icons/${native.hashCode}.png';
              Directory('/tmp/bardash_icons').createSync(recursive: true);
              if (IconShim.rasterSvg(native, pngPath, w: 32, h: 32)) {
                _svgCache[native] = pngPath;
                _themedPath = pngPath;
                _themedMiss = false;
                return pngPath;
              }
            } else {
              _themedPath = native;
              _themedMiss = false;
              return native;
            }
          }
        }
        // 2) Fallback: manual index.theme search + rsvg-convert
        final found = _findIconInDirs(searchDirs, variant);
        if (found == null) continue;
        if (found.endsWith('.svg')) {
          final cached = _svgCache[found];
          if (cached != null && File(cached).existsSync()) {
            _themedPath = cached;
            _themedMiss = false;
            return cached;
          }
          final pngPath = '/tmp/bardash_icons/${found.hashCode}.png';
          Directory('/tmp/bardash_icons').createSync(recursive: true);
          Process.runSync(
            'rsvg-convert',
            ['-w', '32', '-h', '32', '-o', pngPath, found],
            runInShell: true,
          );
          if (File(pngPath).existsSync()) {
            _svgCache[found] = pngPath;
            _themedPath = pngPath;
            _themedMiss = false;
            return pngPath;
          }
        }
        _themedPath = found;
        _themedMiss = false;
        return found;
      }
    }
    _themedMiss = true;
    _themedPath = null;
    return null;
  }
}

/// Test the GTK-aligned icon theme lookup — call from a test script.
void testIconTheme() {
  print('=== Icon theme lookup test ===\n');
  final dirs = _buildThemeDirs(_TrayItem._activeTheme());
  print('Theme dirs (${dirs.length} total):');
  for (final d in dirs.take(15)) {
    print('  $d');
  }
  if (dirs.length > 15) print('  ... (${dirs.length - 15} more)');

  for (final name in ['blueman-tray',
      'org.cryptomator.Cryptomator.tray-symbolic',
      'firefox', 'discord', 'telegram']) {
    String? found;
    for (final v in _iconNameVariants(name)) {
      found = _findIconInDirs(dirs, v);
      if (found != null) break;
    }
    print('  ${name.padRight(45)} ${found != null ? "✅ $found" : "❌"}');
  }
  print('\n=== Done ===');
}

// ── SNI Module ─────────────────────────────────────────────────────

class SniModule extends BarModule {
  @override
  String get name => 'sni';

  final List<_TrayItem> _items = [];
  DBusClient? _bus;
  final List<async.StreamSubscription> _watcherSubs = [];
  bool _connecting = false;
  bool _connected = false;
  int _maxIcons = 8;
  WaylandConnection? _connection;
  int _parentWidth = 1920;
  int _parentHeight = 30;
  bool _openUpward = true;
  int _openGen = 0;
  async.Timer? _paintDebounce;

  /// Called by the bar once the layer surface exists.
  void attach(
    WaylandConnection connection,
    WlSurface parent, {
    int parentWidth = 1920,
    int parentHeight = 30,
    bool openUpward = true,
  }) {
    _connection = connection;
    _parentWidth = parentWidth;
    _parentHeight = parentHeight;
    _openUpward = openUpward;
  }

  @override
  void init(Map<String, String> config) {
    super.init(config);
    format = '';
    // Polling is a fallback; live updates come from D-Bus signals.
    interval = parseInt(config, 'interval', 10);
    _maxIcons = parseInt(config, 'max-icons', 8);
  }

  void _notifyChanged() {
    // Coalesce bursts of NewIcon / PropertiesChanged into one paint.
    _paintDebounce?.cancel();
    _paintDebounce = async.Timer(const Duration(milliseconds: 32), () {
      requestRepaint?.call();
    });
  }

  void _connect() {
    if (_bus != null || _connecting) return;
    _connecting = true;
    async.Timer.run(() async {
      try {
        _bus = DBusClient.session();
        await _registerHost();
        await _subscribeWatcher();
        await _discoverItems();
        _connected = true;
        _notifyChanged();
      } catch (e) {
        stderr.writeln('[sni] connect failed: $e');
        _bus = null;
        _connected = false;
      } finally {
        _connecting = false;
      }
    });
  }

  Future<void> _registerHost() async {
    final watcher = DBusRemoteObject(
      _bus!,
      name: 'org.kde.StatusNotifierWatcher',
      path: DBusObjectPath('/StatusNotifierWatcher'),
    );
    // Tell the watcher we are a tray host so items are allowed to register.
    try {
      await watcher.callMethod(
        'org.kde.StatusNotifierWatcher',
        'RegisterStatusNotifierHost',
        [DBusString('org.freedesktop.StatusNotifierHost-bardash')],
      );
    } catch (e) {
      stderr.writeln('[sni] RegisterStatusNotifierHost: $e');
    }
  }

  Future<void> _subscribeWatcher() async {
    for (final s in _watcherSubs) {
      await s.cancel();
    }
    _watcherSubs.clear();

    const iface = 'org.kde.StatusNotifierWatcher';
    final path = DBusObjectPath('/StatusNotifierWatcher');

    void listen(String name, void Function(String service) handler) {
      final stream = DBusSignalStream(
        _bus!,
        interface: iface,
        name: name,
        path: path,
      );
      _watcherSubs.add(stream.listen((sig) {
        if (sig.values.isEmpty) return;
        final v = sig.values[0];
        if (v is DBusString) {
          handler(v.value);
        }
      }));
    }

    listen('StatusNotifierItemRegistered', (svc) {
      _addItemFromService(svc).then((_) => _notifyChanged());
    });
    listen('StatusNotifierItemUnregistered', (svc) {
      _removeItemFromService(svc);
      _notifyChanged();
    });

    // If the watcher itself restarts, re-discover.
    _watcherSubs.add(DBusSignalStream(
      _bus!,
      interface: 'org.freedesktop.DBus',
      name: 'NameOwnerChanged',
    ).listen((sig) {
      if (sig.values.length < 3) return;
      final name = sig.values[0];
      final newOwner = sig.values[2];
      if (name is! DBusString) return;
      if (name.value != 'org.kde.StatusNotifierWatcher') return;
      if (newOwner is DBusString && newOwner.value.isNotEmpty) {
        _registerHost().then((_) => _discoverItems()).then((_) {
          _notifyChanged();
        });
      }
    }));
  }

  /// Parse watcher service string: "bus.name/path" or just "bus.name".
  static (String busName, String objectPath) _parseService(String service) {
    if (service.contains('/')) {
      final slash = service.indexOf('/');
      var busName = service.substring(0, slash);
      var objectPath = service.substring(slash);
      if (!objectPath.startsWith('/')) objectPath = '/$objectPath';
      return (busName, objectPath);
    }
    return (service, '/StatusNotifierItem');
  }

  Future<void> _discoverItems() async {
    if (_bus == null) return;
    try {
      final watcher = DBusRemoteObject(
        _bus!,
        name: 'org.kde.StatusNotifierWatcher',
        path: DBusObjectPath('/StatusNotifierWatcher'),
      );
      final result = await watcher.getProperty(
        'org.kde.StatusNotifierWatcher',
        'RegisteredStatusNotifierItems',
      );
      final seen = <String>{};
      if (result is DBusArray) {
        for (final item in result.children) {
          if (item is! DBusString) continue;
          final (busName, objectPath) = _parseService(item.value);
          seen.add('$busName$objectPath');
          await _addItem(busName, objectPath);
        }
      }
      // Drop items no longer registered.
      final removed = _items.where((i) => !seen.contains(i.key)).toList();
      for (final i in removed) {
        i.cancelListeners();
        _items.remove(i);
      }
    } catch (e) {
      stderr.writeln('[sni] discover: $e');
    }
  }

  Future<void> _addItemFromService(String service) async {
    final (busName, objectPath) = _parseService(service);
    await _addItem(busName, objectPath);
  }

  Future<void> _addItem(String busName, String objectPath) async {
    if (_bus == null) return;
    if (_items.any((i) => i.busName == busName && i.objectPath == objectPath)) {
      final existing = _items.firstWhere(
        (i) => i.busName == busName && i.objectPath == objectPath,
      );
      await existing.refreshIcons(_bus!);
      return;
    }

    final ti = _TrayItem(busName, objectPath);
    try {
      await ti.refreshIcons(_bus!);
    } catch (e) {
      stderr.writeln('[sni] load $busName: $e');
    }
    ti.listenForChanges(_bus!, _notifyChanged);
    _items.add(ti);
    stderr.writeln(
      '[sni] +item ${ti.id.isNotEmpty ? ti.id : busName} '
      'icon=${ti.iconName.isNotEmpty ? ti.iconName : "(pixmap)"} '
      'title=${ti.title} px=${ti.pixmapW}x${ti.pixmapH}',
    );
  }

  void _removeItemFromService(String service) {
    final (busName, objectPath) = _parseService(service);
    // Unregister may be bus name only — remove all paths for that name.
    final before = _items.length;
    if (service.contains('/')) {
      _items.removeWhere((i) {
        final match = i.busName == busName && i.objectPath == objectPath;
        if (match) i.cancelListeners();
        return match;
      });
    } else {
      _items.removeWhere((i) {
        final match = i.busName == busName;
        if (match) i.cancelListeners();
        return match;
      });
    }
    if (_items.length != before) {
      stderr.writeln('[sni] -item $service');
    }
  }

  @override
  void update() {
    if (_bus == null) {
      _connect();
    } else if (_connected) {
      // Quiet reconcile — only repaint if the item set actually changes.
      final before = _items.map((i) => i.key).join(',');
      _discoverItems().then((_) {
        final after = _items.map((i) => i.key).join(',');
        if (before != after) _notifyChanged();
      });
    }
    output = '';
  }

  // Density-driven tray icon scale (see [BarMetrics]).
  double get _iconSize => BarMetrics.current.iconSlot.toDouble();
  double get _iconSpacing => BarMetrics.current.trayIconGap.toDouble();
  double get _iconStride => _iconSize + _iconSpacing;

  int _hoveredIndex(double moduleX) {
    if (hoverX < 0 || _items.isEmpty) return -1;
    var hx = moduleX;
    for (var i = 0; i < _items.length && i < _maxIcons; i++) {
      if (hoverX >= hx && hoverX < hx + _iconSize) return i;
      hx += _iconStride;
    }
    return -1;
  }

  void _applyHoverTooltip(double moduleX, double moduleY) {
    final hovered = _hoveredIndex(moduleX);
    if (hovered >= 0 && hovered < _items.length) {
      final ti = _items[hovered];
      tooltip = ti.title.isNotEmpty
          ? ti.title
          : ti.iconName.isNotEmpty
              ? ti.iconName
              : ti.id.isNotEmpty
                  ? ti.id
                  : '';
      tooltipAnchorX = moduleX + hovered * _iconStride + _iconSize / 2;
      tooltipAnchorY = moduleY + _iconSize / 2;
    } else {
      tooltip = '';
      tooltipAnchorX = -1;
      tooltipAnchorY = -1;
    }
  }

  @override
  void prepareHoverTooltip(double moduleX, double moduleY) {
    _applyHoverTooltip(moduleX, moduleY);
  }

  @override
  Object get layoutToken =>
      '${_items.length}:$_maxIcons:${_items.map((i) => i.key).join('|')}';

  @override
  double measure(Painter painter) {
    if (_items.isEmpty) return 0;
    final n = _items.take(_maxIcons).length;
    return n * _iconSize + (n - 1) * _iconSpacing;
  }

  @override
  double draw(Painter painter, double x, double y) {
    if (_items.isEmpty) return 0;
    _noteModuleOrigin(x, painter.height);

    final hovered = _hoveredIndex(x);
    var cx = x;

    for (var i = 0; i < _items.length && i < _maxIcons; i++) {
      final item = _items[i];
      if (i == hovered) {
        painter.drawRect(
          Rect.fromLTWH(cx - 1, y + (_iconSize - 16) / 2 - 1, _iconSize + 2, _iconSize + 2),
          Paint()..color = const Color(0x60, 0x70, 0x90),
        );
      }

      // Prefer themed file icons; else pixmap (pixel path is reliable).
      final themed = (item.isElectronLike && item.pixmapData != null)
          ? null
          : item.findThemedIcon();
      final iy = y + (_iconSize - 16) / 2;
      if (themed != null) {
        painter.drawImage(themed, cx, iy,
            width: _iconSize, height: _iconSize);
      } else if (item.pixmapData != null &&
          item.pixmapW > 0 &&
          item.pixmapH > 0) {
        // Pixel draw is the reliable path; PNG is only an optimization.
        _drawPixmap(painter, item, cx, iy, _iconSize);
      } else if (item.pixmapPath != null) {
        painter.drawImage(item.pixmapPath!, cx, iy,
            width: _iconSize, height: _iconSize);
      } else {
        final label = item.iconName.isNotEmpty
            ? item.iconName[0].toUpperCase()
            : item.id.isNotEmpty
                ? item.id[0].toUpperCase()
                : item.title.isNotEmpty
                    ? item.title[0].toUpperCase()
                    : '?';
        painter.drawRect(
          Rect.fromLTWH(cx, y + (_iconSize - 14) / 2, 14, 14),
          Paint()..color = const Color(0x50, 0x50, 0x60),
        );
        painter.drawText(
          label,
          Offset(cx + 3, y + 1),
          color: const Color(0xc0, 0xc0, 0xc0),
          size: 11,
        );
      }
      cx += _iconSize;
      if (i < _items.length - 1) cx += _iconSpacing;
    }

    _applyHoverTooltip(x, y);
    return cx - x;
  }

  void _drawPixmap(Painter painter, _TrayItem item, double x, double y, double size) {
    if (item.pixmapW <= 0 || item.pixmapH <= 0 || item.pixmapData == null) {
      return;
    }
    // pixmapData is already scaled RGBA (see loadPixmap).
    final scaleX = size / item.pixmapW;
    final scaleY = size / item.pixmapH;
    final data = item.pixmapData!;
    final stride = item.pixmapW * 4;
    for (var py = 0; py < item.pixmapH; py++) {
      for (var px = 0; px < item.pixmapW; px++) {
        final off = py * stride + px * 4;
        if (off + 3 >= data.length) continue;
        final a = data[off + 3];
        if (a == 0) continue;
        painter.drawRect(
          Rect.fromLTWH(x + px * scaleX, y + py * scaleY, scaleX, scaleY),
          Paint()
            ..color = Color(data[off], data[off + 1], data[off + 2], a),
        );
      }
    }
  }

  Future<void> _activateTrayItem(
    _TrayItem item, {
    required bool right,
    required double localX,
  }) async {
    if (_bus == null) return;
    final obj = DBusRemoteObject(
      _bus!,
      name: item.busName,
      path: DBusObjectPath(item.objectPath),
    );
    final args = [DBusInt32(0), DBusInt32(0)];

    // Refresh Menu path in case it arrived late.
    if (item.menuPath.isEmpty) {
      await item.loadProperties(_bus!);
    }

    if (right || item.itemIsMenu) {
      // Toggle: second right-click closes an open menu.
      if (TrayMenuController.isOpen) {
        TrayMenuController.close();
        return;
      }

      // 1) Prefer com.canonical.dbusmenu (1Password, Blueman, …).
      if (item.menuPath.isNotEmpty && _connection != null) {
        // Prefer absolute bar X from the click (hoverX), not estimated module origin.
        final menuX = hoverX >= 0
            ? hoverX.round()
            : (_moduleX + localX).round();
        final gen = ++_openGen;
        try {
          await TrayMenuController.open(
            connection: _connection!,
            bus: _bus!,
            service: item.busName,
            menuPath: item.menuPath,
            anchorX: menuX,
            parentWidth: _parentWidth,
            parentHeight: _parentHeight,
            openUpward: _openUpward,
          );
          return;
        } catch (e, st) {
          if (gen == _openGen) {
            stderr.writeln('[sni] dbusmenu failed: $e\n$st');
          }
        }
      }

      // 2) Classic SNI ContextMenu (optional).
      try {
        await obj.callMethod(
          'org.kde.StatusNotifierItem',
          'ContextMenu',
          args,
        );
        return;
      } catch (_) {}

      // 3) SecondaryActivate fallback.
      try {
        await obj.callMethod(
          'org.kde.StatusNotifierItem',
          'SecondaryActivate',
          args,
        );
      } catch (e) {
        stderr.writeln('[sni] right-click failed: $e');
      }
      return;
    }

    // Left click closes menu first, then Activate.
    if (TrayMenuController.isOpen) {
      TrayMenuController.close();
    }
    try {
      await obj.callMethod(
        'org.kde.StatusNotifierItem',
        'Activate',
        args,
      );
    } catch (e) {
      if (item.menuPath.isNotEmpty) {
        await _activateTrayItem(item, right: true, localX: localX);
      } else {
        stderr.writeln('[sni] Activate failed: $e');
      }
    }
  }

  double _moduleX = 0;

  /// Called from draw so menu can be placed in parent coordinates.
  void _noteModuleOrigin(double x, double height) {
    _moduleX = x;
  }

  _TrayItem? _itemAtLocalX(double x) {
    var cx = 0.0;
    for (final item in _items.take(_maxIcons)) {
      if (x >= cx && x < cx + _iconSize) return item;
      cx += _iconStride;
    }
    return null;
  }

  @override
  bool get hasClick => _items.isNotEmpty;

  @override
  void onClick(double x, double y, {int button = 0x110}) {
    final item = _itemAtLocalX(x);
    if (item == null) {
      if (TrayMenuController.isOpen) TrayMenuController.close();
      return;
    }
    final right = button == 0x111;
    _activateTrayItem(item, right: right, localX: x);
  }
}
