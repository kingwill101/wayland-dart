/// Dbusmenu-backed tray popup menu for StatusNotifier items.
///
/// The menu is a dedicated `zwlr_layer_shell` surface on the overlay layer so
/// it stacks above normal windows. Subsurfaces of the bar were clipped /
/// covered by clients, which is why the menu only appeared when a window
/// happened to sit under it.
library;

import 'dart:async' show Completer, scheduleMicrotask, TimeoutException;
import 'dart:io' show stderr;

import 'package:dbus/dbus.dart';
import 'package:wayland/wayland.dart';
import 'package:window_toolkit/window_toolkit.dart';

class DbusMenuEntry {
  final int id;
  final String label;
  final bool separator;
  final bool enabled;
  final bool visible;

  const DbusMenuEntry({
    required this.id,
    required this.label,
    this.separator = false,
    this.enabled = true,
    this.visible = true,
  });
}

Future<List<DbusMenuEntry>> fetchDbusMenu(
  DBusClient bus,
  String service,
  String menuPath,
) async {
  final obj = DBusRemoteObject(
    bus,
    name: service,
    path: DBusObjectPath(menuPath),
  );

  try {
    await obj.callMethod(
      'com.canonical.dbusmenu',
      'AboutToShow',
      [DBusInt32(0)],
    );
  } catch (e) {
    stderr.writeln('[dbusmenu] AboutToShow: $e');
  }

  final result = await obj.callMethod(
    'com.canonical.dbusmenu',
    'GetLayout',
    [DBusInt32(0), DBusInt32(3), DBusArray.string(const [])],
  );

  if (result.returnValues.length < 2) return const [];

  final entries = <DbusMenuEntry>[];

  void walk(DBusValue node, {int depth = 0}) {
    var n = node;
    if (n is DBusVariant) n = n.value;
    if (n is! DBusStruct || n.children.length < 3) return;

    final idVal = n.children[0];
    final propsVal = n.children[1];
    final kidsVal = n.children[2];

    int? id;
    if (idVal is DBusInt32) id = idVal.value;
    if (idVal is DBusUint32) id = idVal.value;
    if (id == null) return;

    final props = <String, DBusValue>{};
    if (propsVal is DBusDict) {
      for (final entry in propsVal.children.entries) {
        final k = entry.key;
        var v = entry.value;
        if (v is DBusVariant) v = v.value;
        if (k is DBusString) props[k.value] = v;
      }
    }

    final type = props['type'] is DBusString
        ? (props['type'] as DBusString).value
        : 'standard';
    final label = props['label'] is DBusString
        ? (props['label'] as DBusString).value.replaceAll('_', '')
        : '';
    final enabled = props['enabled'] is DBusBoolean
        ? (props['enabled'] as DBusBoolean).value
        : true;
    final visible = props['visible'] is DBusBoolean
        ? (props['visible'] as DBusBoolean).value
        : true;

    if (depth == 1 && visible) {
      entries.add(DbusMenuEntry(
        id: id,
        label: label,
        separator: type == 'separator',
        enabled: enabled,
        visible: visible,
      ));
    }

    if (depth == 0 && kidsVal is DBusArray) {
      for (final child in kidsVal.children) {
        walk(child, depth: 1);
      }
    }
  }

  walk(result.returnValues[1], depth: 0);
  return entries;
}

Future<void> dbusMenuClick(
  DBusClient bus,
  String service,
  String menuPath,
  int itemId,
) async {
  final obj = DBusRemoteObject(
    bus,
    name: service,
    path: DBusObjectPath(menuPath),
  );
  final ts = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  try {
    await obj.callMethod(
      'com.canonical.dbusmenu',
      'Event',
      [
        DBusInt32(itemId),
        DBusString('clicked'),
        DBusVariant(DBusInt32(0)),
        DBusUint32(ts),
      ],
    );
  } catch (e) {
    stderr.writeln('[dbusmenu] Event failed: $e');
  }
}

class TrayMenuController {
  static TrayMenuOverlay? _active;
  static int _generation = 0;

  static bool get isOpen => _active?.isOpen ?? false;

  static void close() {
    _generation++;
    _active?.destroy();
    _active = null;
  }

  static Future<void> open({
    required WaylandConnection connection,
    required DBusClient bus,
    required String service,
    required String menuPath,
    required int anchorX,
    required int parentWidth,
    required int parentHeight,
    required bool openUpward,
  }) async {
    final gen = ++_generation;
    _active?.destroy();
    _active = null;

    List<DbusMenuEntry> items;
    try {
      items = await fetchDbusMenu(bus, service, menuPath);
    } catch (e, st) {
      stderr.writeln('[dbusmenu] fetch failed: $e\n$st');
      return;
    }
    if (gen != _generation) return;

    items = items.where((e) => e.visible).toList();
    if (items.isEmpty) {
      stderr.writeln('[dbusmenu] empty menu');
      return;
    }

    if (connection.layerShell == null) {
      stderr.writeln('[dbusmenu] layer shell not available');
      return;
    }

    late final TrayMenuOverlay menu;
    menu = TrayMenuOverlay(
      connection: connection,
      bus: bus,
      service: service,
      menuPath: menuPath,
      items: items,
      parentWidth: parentWidth,
      parentHeight: parentHeight,
      openUpward: openUpward,
      onClosed: () {
        if (identical(_active, menu)) _active = null;
      },
    );
    _active = menu;
    await menu.show(anchorX);
  }
}

/// Tray context menu as an independent overlay layer surface.
///
/// No bar subsurface and no full-screen dismiss catcher — both caused the
/// black-layer / only-visible-over-window bugs. Outside clicks on the bar
/// still close via [TrayMenuController.close]; Escape closes from here.
class TrayMenuOverlay with EventReceiver {
  final WaylandConnection connection;
  final DBusClient bus;
  final String service;
  final String menuPath;
  final List<DbusMenuEntry> items;
  final int parentHeight;
  final int parentWidth;
  final bool openUpward;
  final void Function()? onClosed;

  WlSurface? _menuSurface;
  LayerSurfaceV1? _menuLayer;
  /// Double-buffered SHM: paint the free slot while the compositor holds
  /// the other — prevents mid-hover tear / partial frames.
  final List<WlShmPool?> _menuPools = [null, null];
  final List<WlBuffer?> _menuBuffers = [null, null];
  final List<int> _menuFds = [-1, -1];
  final List<bool> _menuBusy = [false, false];
  int _menuFront = 0;
  bool _menuNeedsPaint = false;
  /// Coalesce hover repaints to one present per event-loop turn.
  bool _paintScheduled = false;
  bool _presenting = false;

  /// Full-output click catcher — transparent, no black fill via Skia.
  WlSurface? _dismissSurface;
  LayerSurfaceV1? _dismissLayer;
  WlShmPool? _dismissPool;
  WlBuffer? _dismissBuffer;
  int _dismissFd = -1;
  int _dismissW = 0;
  int _dismissH = 0;

  int _w = 0;
  int _h = 0;
  bool _open = false;
  int _hoverIndex = -1;
  int _openedAtMs = 0;

  static const _itemH = 28;
  static const _pad = 8;
  static const _fontSize = 13.0;
  static const _gap = 4;
  // Opaque panel colors (alpha 255).
  static const _bg = Color(32, 32, 36);
  static const _border = Color(90, 90, 100);
  static const _hover = Color(55, 85, 150);
  static const _text = Color(240, 240, 245);
  static const _textDim = Color(130, 130, 140);
  static const _sep = Color(70, 70, 80);

  TrayMenuOverlay({
    required this.connection,
    required this.bus,
    required this.service,
    required this.menuPath,
    required this.items,
    this.parentHeight = 30,
    this.parentWidth = 1920,
    this.openUpward = true,
    this.onClosed,
  });

  bool get isOpen => _open;

  Future<void> show(int anchorX) async {
    var maxChars = 8;
    for (final e in items) {
      if (e.label.length > maxChars) maxChars = e.label.length;
    }
    _w = (maxChars * 8 + _pad * 2 + 24).clamp(160, 420);
    _h = items.length * _itemH + _pad * 2;

    final shell = connection.layerShell;
    if (shell == null) {
      stderr.writeln('[dbusmenu] no layer shell');
      destroy();
      return;
    }

    // Dismiss first so the menu layer stacks above it.
    if (!_createDismiss(shell)) {
      stderr.writeln('[dbusmenu] dismiss create failed');
      destroy();
      return;
    }
    if (!_createMenu(shell, anchorX)) {
      stderr.writeln('[dbusmenu] menu create failed');
      destroy();
      return;
    }

    // Initial commits without buffers → compositor sends configure.
    // Await configure via callbacks (main loop dispatches) — never nest
    // blocking dispatchTimeout while the app tick also reads the socket.
    _dismissSurface!.commit();
    _menuSurface!.commit();
    final ok = await _waitConfigureAsync();

    if (!ok) {
      stderr.writeln('[dbusmenu] configure timeout');
      destroy();
      return;
    }

    _mapDismiss();
    _mapMenu();

    _open = true;
    _openedAtMs = DateTime.now().millisecondsSinceEpoch;
    Application.instance.removeEventReceiver(this);
    Application.instance.prependEventReceiver(this);

    stderr.writeln(
      '[dbusmenu] open layer ${_w}x$_h items=${items.length} '
      'menu=${_menuSurface!.objectId} anchorX=$anchorX',
    );
  }

  void hide() {
    if (!_open && _menuSurface == null && _dismissSurface == null) return;
    _open = false;
    Application.instance.removeEventReceiver(this);
    // Unmap by attaching a null buffer is ideal; destroy is simpler/safer.
    _teardownMenu();
    _teardownDismiss();
    onClosed?.call();
    stderr.writeln('[dbusmenu] hide');
  }

  void destroy() {
    hide();
  }

  @override
  void onEvent(Event event) {
    if (!_open) return;

    final surf = connection.pointerSurfaceId;
    final onMenu = surf != null && surf == _menuSurface?.objectId;
    final onDismiss = surf != null && surf == _dismissSurface?.objectId;
    final age = DateTime.now().millisecondsSinceEpoch - _openedAtMs;

    // Grace period after open so the right-click that opened us is ignored.
    if (age < 250) {
      if (onMenu || onDismiss) event.accept();
      return;
    }

    if (event is KeyEvent && event.isPressed) {
      if (event.key == 1 || event.character == '\x1b') {
        hide();
        event.accept();
      }
      return;
    }

    if (event is MouseLeaveEvent) {
      // Pointer left whatever surface it was on (menu/dismiss/bar).
      if (_hoverIndex != -1) {
        _hoverIndex = -1;
        _scheduleRepaint();
      }
      return;
    }

    if (onDismiss) {
      if (_hoverIndex != -1) {
        _hoverIndex = -1;
        _scheduleRepaint();
      }
      if (event is MouseButtonEvent && event.isPressed) {
        hide();
        event.accept();
      }
      return;
    }

    if (onMenu) {
      if (event is MouseMotionEvent || event is MouseEnterEvent) {
        final x = event is MouseMotionEvent
            ? event.x
            : (event as MouseEnterEvent).x;
        final y = event is MouseMotionEvent
            ? event.y
            : (event as MouseEnterEvent).y;
        final next = _hitIndex(x, y);
        if (next != _hoverIndex) {
          _hoverIndex = next;
          _scheduleRepaint();
        }
        event.accept();
        return;
      }
      if (event is MouseButtonEvent && event.isPressed) {
        // Require pointer to be inside the menu content box — never activate
        // from stale coords or a click that is only "near" the menu.
        final idx = _hitIndex(event.x, event.y);
        if (idx >= 0 && idx < items.length) {
          final item = items[idx];
          if (!item.separator && item.enabled) {
            stderr.writeln(
              '[dbusmenu] activate id=${item.id} "${item.label}"',
            );
            dbusMenuClick(bus, service, menuPath, item.id);
          }
          hide();
        } else {
          // Click on the menu surface but outside rows (padding) → just close.
          hide();
        }
        event.accept();
      }
      return;
    }

    // Clicks that reached us but are not on menu/dismiss (e.g. bar).
    if (event is MouseButtonEvent && event.isPressed) {
      hide();
    }
  }

  /// True when surface-local ([x], [y]) is inside the menu panel.
  bool _inMenuBounds(double x, double y) =>
      x >= 0 && x < _w && y >= 0 && y < _h;

  /// Row index under ([x], [y]), or -1 if outside the panel / on a separator.
  int _hitIndex(double x, double y) {
    if (!_inMenuBounds(x, y)) return -1;
    final rel = y - _pad;
    if (rel < 0) return -1;
    final idx = rel ~/ _itemH;
    if (idx < 0 || idx >= items.length) return -1;
    // Bottom padding past last row.
    if (y >= _pad + items.length * _itemH) return -1;
    if (items[idx].separator) return -1;
    return idx;
  }

  // ── Layer surface setup ──────────────────────────────────────────

  bool _createMenu(LayerShellV1 shell, int anchorX) {
    _menuSurface = connection.compositor.createSurface().getOrElse((e) {
      stderr.writeln('[tray-menu] menu surface: $e');
      return WlSurface(connection.context);
    });

    _menuLayer = shell
        .getLayerSurface(
          _menuSurface!,
          connection.output,
          LayerShellV1Layer.overlay.enumValue,
          'bardash-tray-menu',
        )
        .getOrElse((e) {
      stderr.writeln('[tray-menu] menu layer: $e');
      return LayerSurfaceV1(connection.context);
    });

    final menuX = (anchorX - 8).clamp(4, (parentWidth - _w - 4).clamp(0, parentWidth));
    final preferRight = menuX + _w / 2 > parentWidth / 2;

    if (openUpward) {
      final bottom = parentHeight + _gap;
      if (preferRight) {
        final right = (parentWidth - menuX - _w).clamp(0, parentWidth);
        _menuLayer!.setAnchor(
          LayerSurfaceV1Anchor.bottom.enumValue |
              LayerSurfaceV1Anchor.right.enumValue,
        );
        _menuLayer!.setMargin(0, right, bottom, 0);
      } else {
        _menuLayer!.setAnchor(
          LayerSurfaceV1Anchor.bottom.enumValue |
              LayerSurfaceV1Anchor.left.enumValue,
        );
        _menuLayer!.setMargin(0, 0, bottom, menuX);
      }
    } else {
      final top = parentHeight + _gap;
      if (preferRight) {
        final right = (parentWidth - menuX - _w).clamp(0, parentWidth);
        _menuLayer!.setAnchor(
          LayerSurfaceV1Anchor.top.enumValue |
              LayerSurfaceV1Anchor.right.enumValue,
        );
        _menuLayer!.setMargin(top, right, 0, 0);
      } else {
        _menuLayer!.setAnchor(
          LayerSurfaceV1Anchor.top.enumValue |
              LayerSurfaceV1Anchor.left.enumValue,
        );
        _menuLayer!.setMargin(top, 0, 0, menuX);
      }
    }

    _menuLayer!.setSize(_w, _h);
    _menuLayer!.setExclusiveZone(0);
    _menuLayer!.setKeyboardInteractivity(
      LayerSurfaceV1KeyboardInteractivity.exclusive.enumValue,
    );

    _menuLayer!.onConfigure((e) {
      _menuLayer!.ackConfigure(e.serial);
    });
    _menuLayer!.onClosed((_) {
      hide();
    });

    return true;
  }

  bool _createDismiss(LayerShellV1 shell) {
    _dismissSurface = connection.compositor.createSurface().getOrElse((e) {
      stderr.writeln('[tray-menu] dismiss surface: $e');
      return WlSurface(connection.context);
    });

    _dismissLayer = shell
        .getLayerSurface(
          _dismissSurface!,
          connection.output,
          LayerShellV1Layer.overlay.enumValue,
          'bardash-tray-dismiss',
        )
        .getOrElse((e) {
      stderr.writeln('[tray-menu] dismiss layer: $e');
      return LayerSurfaceV1(connection.context);
    });

    // Stretch to full output except the bar strip so tray icons stay free
    // (avoids a full-screen layer sitting on top of the bar / tray).
    _dismissLayer!.setAnchor(
      LayerSurfaceV1Anchor.top.enumValue |
          LayerSurfaceV1Anchor.bottom.enumValue |
          LayerSurfaceV1Anchor.left.enumValue |
          LayerSurfaceV1Anchor.right.enumValue,
    );
    if (openUpward) {
      // Bottom bar: leave [outputH - parentHeight, outputH) free.
      _dismissLayer!.setMargin(0, 0, parentHeight, 0);
    } else {
      // Top bar: leave the top exclusive strip free.
      _dismissLayer!.setMargin(parentHeight, 0, 0, 0);
    }
    _dismissLayer!.setSize(0, 0);
    _dismissLayer!.setExclusiveZone(-1);
    _dismissLayer!.setKeyboardInteractivity(
      LayerSurfaceV1KeyboardInteractivity.none.enumValue,
    );

    _dismissLayer!.onConfigure((e) {
      _dismissLayer!.ackConfigure(e.serial);
      if (e.width > 0 && e.height > 0) {
        _dismissW = e.width;
        _dismissH = e.height;
      }
    });
    _dismissLayer!.onClosed((_) {});

    return true;
  }

  /// Wait for configure events without nesting Wayland dispatch.
  Future<bool> _waitConfigureAsync() async {
    final done = Completer<void>();
    var sawMenu = false;
    var sawDismiss = false;

    void tryComplete() {
      if (sawMenu && sawDismiss && !done.isCompleted) {
        done.complete();
      }
    }

    _menuLayer!.onConfigure((e) {
      _menuLayer!.ackConfigure(e.serial);
      sawMenu = true;
      tryComplete();
    });
    _dismissLayer!.onConfigure((e) {
      _dismissLayer!.ackConfigure(e.serial);
      if (e.width > 0 && e.height > 0) {
        _dismissW = e.width;
        _dismissH = e.height;
      } else {
        _dismissW = parentWidth.clamp(1, 7680);
        _dismissH = 1440;
      }
      sawDismiss = true;
      tryComplete();
    });

    try {
      await done.future.timeout(const Duration(milliseconds: 500));
      return true;
    } on TimeoutException {
      return false;
    }
  }

  void _mapMenu() {
    final stride = _w * 4;
    final slotSize = stride * _h;

    for (var i = 0; i < 2; i++) {
      final fd = createAnonymousFile(slotSize);
      if (fd < 0) return;
      _menuFds[i] = fd;
      final pool = connection.shm.createPool(fd, slotSize).getOrElse((e) {
        stderr.writeln('[tray-menu] menu pool $i: $e');
        return WlShmPool(connection.context);
      });
      _menuPools[i] = pool;
      final buf = pool.createBuffer(0, _w, _h, stride, 0).getOrElse((e) {
        stderr.writeln('[tray-menu] menu buffer $i: $e');
        return WlBuffer(connection.context);
      });
      final slot = i;
      buf.onRelease((_) {
        _menuBusy[slot] = false;
        if (_menuNeedsPaint && _open) {
          _scheduleRepaint();
        }
      });
      _menuBuffers[i] = buf;
      _menuBusy[i] = false;
    }

    _menuFront = 0;
    _menuNeedsPaint = false;
    _paintScheduled = false;
    _presenting = false;
    // Initial frame — safe before event loop re-entry.
    _presentMenu();
  }

  void _mapDismiss() {
    var w = _dismissW;
    var h = _dismissH;
    if (w <= 0 || h <= 0) {
      w = parentWidth.clamp(1, 7680);
      h = 1440;
      _dismissW = w;
      _dismissH = h;
    }
    final stride = w * 4;
    final size = stride * h;
    _dismissFd = createAnonymousFile(size);
    if (_dismissFd < 0) return;
    _dismissPool =
        connection.shm.createPool(_dismissFd, size).getOrElse((e) {
      stderr.writeln('[tray-menu] dismiss pool: $e');
      return WlShmPool(connection.context);
    });
    _dismissBuffer =
        _dismissPool!.createBuffer(0, w, h, stride, 0).getOrElse((e) {
      stderr.writeln('[tray-menu] dismiss buffer: $e');
      return WlBuffer(connection.context);
    });

    // Fully transparent via Skia (same path as working tooltips) — NOT a
    // raw ARGB fill that some compositors treat as opaque black.
    final painter = SkiaPainter(_dismissFd, w, h);
    try {
      painter.clear(const Color(0, 0, 0, 0));
      painter.flush();
    } finally {
      painter.dispose();
    }

    _dismissSurface!.attach(_dismissBuffer!, 0, 0);
    _dismissSurface!.damage(0, 0, w, h);
    _dismissSurface!.commit();
  }

  /// Queue a single present after the current event turn so rapid motion
  /// only paints the final hover index (no flicker / “running” highlight).
  void _scheduleRepaint() {
    _menuNeedsPaint = true;
    if (_paintScheduled) return;
    _paintScheduled = true;
    scheduleMicrotask(() {
      _paintScheduled = false;
      if (!_open || !_menuNeedsPaint) return;
      _presentMenu();
    });
  }

  /// Paint into a free slot and attach it. Never mutates a buffer the
  /// compositor still holds. Does **not** dispatch the Wayland connection
  /// (that re-entered motion/release handlers and made hover thrash).
  void _presentMenu() {
    if (_menuSurface == null || _presenting) {
      _menuNeedsPaint = true;
      return;
    }
    _presenting = true;
    try {
      // Prefer the back buffer; fall back to any free slot.
      var slot = 1 - _menuFront;
      if (_menuBusy[slot] || _menuBuffers[slot] == null) {
        slot = _menuFront;
      }
      if (_menuBusy[slot] ||
          _menuBuffers[slot] == null ||
          _menuFds[slot] < 0) {
        // Compositor still owns both — paint later with latest hover.
        _menuNeedsPaint = true;
        return;
      }

      _paintMenuInto(_menuFds[slot]);
      _menuBusy[slot] = true;
      _menuFront = slot;
      _menuNeedsPaint = false;

      _menuSurface!.attach(_menuBuffers[slot]!, 0, 0);
      _menuSurface!.damage(0, 0, _w, _h);
      _menuSurface!.commit();
    } finally {
      _presenting = false;
    }
  }

  void _paintMenuInto(int fd) {
    if (fd < 0) return;

    final painter = SkiaPainter(fd, _w, _h);
    try {
      painter.clear(_bg);
      painter.drawRect(
        Rect.fromLTWH(0, 0, _w.toDouble(), _h.toDouble()),
        Paint()..color = _bg,
      );
      painter.drawRect(
        Rect.fromLTWH(0.5, 0.5, _w - 1.0, _h - 1.0),
        Paint()
          ..color = _border
          ..style = PaintStyle.stroke
          ..strokeWidth = 1,
      );

      var y = _pad.toDouble();
      for (var i = 0; i < items.length; i++) {
        final item = items[i];
        if (item.separator) {
          painter.drawRect(
            Rect.fromLTWH(8, y + _itemH / 2.0, _w - 16.0, 1),
            Paint()..color = _sep,
          );
        } else {
          if (i == _hoverIndex && item.enabled) {
            painter.drawRect(
              Rect.fromLTWH(2, y + 1, _w - 4.0, _itemH - 2.0),
              Paint()..color = _hover,
            );
          }
          final label = item.label.isEmpty ? ' ' : item.label;
          // Skia draws at baseline — center glyph bounds in the row.
          final bounds = painter.measureTextBounds(
            label,
            size: _fontSize,
            fontFamily: 'sans',
          );
          final originX = _pad.toDouble() - bounds.left;
          final originY = TextLayout.baselineForBounds(y, _itemH.toDouble(), bounds);
          painter.drawText(
            label,
            Offset(originX, originY),
            color: item.enabled ? _text : _textDim,
            size: _fontSize,
            fontFamily: 'sans',
          );
        }
        y += _itemH;
      }
      painter.flush();
    } finally {
      painter.dispose();
    }
  }

  void _teardownMenu() {
    _menuNeedsPaint = false;
    _paintScheduled = false;
    _presenting = false;
    _hoverIndex = -1;
    for (var i = 0; i < 2; i++) {
      _menuBuffers[i]?.destroy();
      _menuBuffers[i] = null;
      _menuPools[i]?.destroy();
      _menuPools[i] = null;
      if (_menuFds[i] >= 0) {
        closeFd(_menuFds[i]);
        _menuFds[i] = -1;
      }
      _menuBusy[i] = false;
    }
    _menuFront = 0;
    _menuLayer?.destroy();
    _menuLayer = null;
    _menuSurface?.destroy();
    _menuSurface = null;
  }

  void _teardownDismiss() {
    _dismissBuffer?.destroy();
    _dismissBuffer = null;
    _dismissPool?.destroy();
    _dismissPool = null;
    if (_dismissFd >= 0) {
      closeFd(_dismissFd);
      _dismissFd = -1;
    }
    _dismissLayer?.destroy();
    _dismissLayer = null;
    _dismissSurface?.destroy();
    _dismissSurface = null;
    _dismissW = 0;
    _dismissH = 0;
  }
}
