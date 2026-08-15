/// A click-to-open network panel for bardash.
///
/// Shows connection details + live link throughput + quick actions.
/// Surface plumbing mirrors `audio_popup.dart` (layer overlay + dismiss).
library;

import 'dart:async' as dart_async;
import 'dart:io';

import 'package:wayland/wayland.dart';
import 'package:window_toolkit/window_toolkit.dart';

import 'native/network_manager.dart';
import 'net_speed.dart';
import 'speed_test_popup.dart';

/// Pure layout + hit-testing for the network panel.
class NetworkPanelLayout {
  final int width;
  final int height;

  NetworkPanelLayout({int? width, int? height})
      : width = width ?? 260,
        height = height ?? 190;

  static const pad = 12;
  static const rowH = 20;
  static const btnH = 24;

  int get btnW => ((width - pad * 3) / 2).round();

  Rect btnSpeedTest() => Rect.fromLTWH(
      pad.toDouble(), (height - pad - btnH).toDouble(), btnW.toDouble(), btnH.toDouble());

  Rect btnSettings() => Rect.fromLTWH(
      (pad + btnW + pad).toDouble(), (height - pad - btnH).toDouble(), btnW.toDouble(), btnH.toDouble());

  bool _inRect(Rect b, double x, double y) =>
      x >= b.left && x <= b.right && y >= b.top && y <= b.bottom;

  bool hitSpeedTest(double x, double y) => _inRect(btnSpeedTest(), x, y);
  bool hitSettings(double x, double y) => _inRect(btnSettings(), x, y);
}

class NetworkPopupController {
  static NetworkPopupOverlay? _active;
  static int _generation = 0;

  static bool get isOpen => _active?.isOpen ?? false;

  static void close() {
    _generation++;
    _active?.destroy();
    _active = null;
  }

  static Future<void> open({
    required WaylandConnection connection,
    required int anchorX,
    required int parentWidth,
    required int parentHeight,
    required bool openUpward,
  }) async {
    _generation++;
    final gen = _generation;
    _active?.destroy();
    _active = null;

    if (connection.layerShell == null) {
      stderr.writeln('[network] layer shell not available');
      return;
    }

    late final NetworkPopupOverlay overlay;
    overlay = NetworkPopupOverlay(
      connection: connection,
      anchorX: anchorX,
      parentWidth: parentWidth,
      parentHeight: parentHeight,
      openUpward: openUpward,
      onClosed: () {
        if (identical(_active, overlay)) _active = null;
      },
    );
    _active = overlay;
    await overlay.show();
    if (gen != _generation) return;
  }
}

class NetworkPopupOverlay with EventReceiver {
  final WaylandConnection connection;
  final int anchorX;
  final int parentWidth;
  final int parentHeight;
  final bool openUpward;
  final void Function()? onClosed;

  WlSurface? _surface;
  LayerSurfaceV1? _layer;
  final List<WlShmPool?> _pools = [null, null];
  final List<WlBuffer?> _buffers = [null, null];
  final List<int> _fds = [-1, -1];
  final List<bool> _busy = [false, false];
  int _front = 0;
  bool _needsPaint = false;
  bool _paintScheduled = false;
  bool _presenting = false;

  WlSurface? _dismissSurface;
  LayerSurfaceV1? _dismissLayer;
  WlBuffer? _dismissBuffer;
  WlShmPool? _dismissPool;
  int _dismissFd = -1;
  int _dismissW = 0;
  int _dismissH = 0;

  late final NetworkPanelLayout _layout;
  bool _open = false;
  int _openedAtMs = 0;
  dart_async.Timer? _tick;

  // Sizes.
  static const _w = 260;
  static const _h = 190;

  // Colors (opaque, alpha 255).
  static const _bg = Color(30, 30, 34);
  static const _border = Color(80, 80, 90);
  static const _text = Color(235, 235, 240);
  static const _dim = Color(140, 140, 155);
  static const _sep = Color(65, 65, 75);
  static const _btn = Color(62, 70, 82);
  static const _btnHover = Color(84, 96, 112);
  static const _icon = Color(0x88, 0xc0, 0xd0);
  static const _up = Color(0xa6, 0xd9, 0xa3);
  static const _down = Color(0xbf, 0x61, 0x6a);

  NetworkPopupOverlay({
    required this.connection,
    required this.anchorX,
    this.parentWidth = 1920,
    this.parentHeight = 30,
    this.openUpward = true,
    this.onClosed,
  }) {
    _layout = NetworkPanelLayout(width: _w, height: _h);
  }

  bool get isOpen => _open;

  Future<void> show() async {
    final shell = connection.layerShell!;
    if (!_createDismiss(shell)) {
      stderr.writeln('[network] dismiss create failed');
      destroy();
      return;
    }
    if (!_createLayer(shell)) {
      stderr.writeln('[network] layer create failed');
      destroy();
      return;
    }

    _dismissSurface!.commit();
    _surface!.commit();
    final ok = await _waitConfigureAsync();
    if (!ok) {
      stderr.writeln('[network] configure timeout');
      destroy();
      return;
    }

    _mapDismiss();
    _mapLayer();

    // Live snapshot + throughput refreshes.
    NetworkManagerClient.instance.addListener((_) => _scheduleRepaint());
    _tick = dart_async.Timer.periodic(const Duration(seconds: 1), (_) {
      NetSpeed.sample();
      _scheduleRepaint();
    });

    _open = true;
    _openedAtMs = DateTime.now().millisecondsSinceEpoch;
    Application.instance.removeEventReceiver(this);
    Application.instance.prependEventReceiver(this);

    stderr.writeln('[network] open overlay $_w x $_h anchorX=$anchorX');
  }

  void hide() {
    if (!_open && _surface == null && _dismissSurface == null) return;
    _open = false;
    Application.instance.removeEventReceiver(this);
    _tick?.cancel();
    _tick = null;
    _teardown();
    onClosed?.call();
  }

  void destroy() => hide();

  @override
  void onEvent(Event event) {
    if (!_open) return;

    final surf = connection.pointerSurfaceId;
    final onLayer = surf != null && surf == _surface?.objectId;
    final onDismiss = surf != null && surf == _dismissSurface?.objectId;
    final age = DateTime.now().millisecondsSinceEpoch - _openedAtMs;

    if (age < 200) {
      if (onLayer || onDismiss) event.accept();
      return;
    }

    if (event is KeyEvent && event.isPressed) {
      if (event.key == 1 || event.character == '\x1b') {
        hide();
        event.accept();
      }
      return;
    }

    if (onDismiss) {
      if (event is MouseButtonEvent && event.isPressed) hide();
      event.accept();
      return;
    }

    if (onLayer) {
      if (event is MouseEnterEvent) {
        event.accept();
        return;
      }
      if (event is MouseButtonEvent && event.isPressed) {
        final x = event.x;
        final y = event.y;
        if (_layout.hitSpeedTest(x, y)) {
          NetworkPopupController.close();
        SpeedTestController.open(
          connection: connection,
          anchorX: anchorX,
          parentWidth: parentWidth,
          parentHeight: parentHeight,
          openUpward: openUpward,
        );
          hide();
        } else if (_layout.hitSettings(x, y)) {
          _run('Settings', 'nm-connection-editor');
          hide();
        } else {
          hide();
        }
        event.accept();
        return;
      }
      return;
    }

    if (event is MouseButtonEvent && event.isPressed) hide();
  }

  String? _resolveCommand(String cmd) {
    try {
      final r = Process.runSync('which', [cmd], runInShell: false);
      if (r.exitCode == 0) return cmd;
    } catch (_) {}
    return null;
  }

  void _run(String label, String cmd) {
    final exe = _resolveCommand(cmd);
    if (exe == null) {
      stderr.writeln('[network] $label: $cmd not found');
      return;
    }
    try {
      stderr.writeln('[network] $label: $exe');
      Process.run(exe, const [], runInShell: false);
    } on ProcessException catch (e) {
      stderr.writeln('[network] $label failed: $e');
    }
  }

  // ── Layer surface setup ────────────────────────────────────────

  bool _createLayer(LayerShellV1 shell) {
    _surface = connection.compositor.createSurface().getOrElse((e) {
      stderr.writeln('[network] surface: $e');
      return WlSurface(connection.context);
    });
    _layer = shell
        .getLayerSurface(
          _surface!,
          connection.output,
          LayerShellV1Layer.overlay.enumValue,
          'bardash-network',
        )
        .getOrElse((e) {
      stderr.writeln('[network] layer: $e');
      return LayerSurfaceV1(connection.context);
    });

    final menuX = (anchorX - 8).clamp(4, parentWidth - _w - 4);
    final preferRight = menuX + _w / 2 > parentWidth / 2;

    if (openUpward) {
      final bottom = parentHeight + 4;
      if (preferRight) {
        final right = (parentWidth - menuX - _w).clamp(0, parentWidth);
        _layer!.setAnchor(LayerSurfaceV1Anchor.bottom.enumValue |
            LayerSurfaceV1Anchor.right.enumValue);
        _layer!.setMargin(0, right, bottom, 0);
      } else {
        _layer!.setAnchor(LayerSurfaceV1Anchor.bottom.enumValue |
            LayerSurfaceV1Anchor.left.enumValue);
        _layer!.setMargin(0, 0, bottom, menuX);
      }
    } else {
      final top = parentHeight + 4;
      if (preferRight) {
        final right = (parentWidth - menuX - _w).clamp(0, parentWidth);
        _layer!.setAnchor(LayerSurfaceV1Anchor.top.enumValue |
            LayerSurfaceV1Anchor.right.enumValue);
        _layer!.setMargin(top, right, 0, 0);
      } else {
        _layer!.setAnchor(LayerSurfaceV1Anchor.top.enumValue |
            LayerSurfaceV1Anchor.left.enumValue);
        _layer!.setMargin(top, 0, 0, menuX);
      }
    }

    _layer!.setSize(_w, _h);
    _layer!.setExclusiveZone(0);
    _layer!.setKeyboardInteractivity(
        LayerSurfaceV1KeyboardInteractivity.exclusive.enumValue);
    _layer!.onConfigure((e) => _layer!.ackConfigure(e.serial));
    _layer!.onClosed((_) => hide());
    return true;
  }

  bool _createDismiss(LayerShellV1 shell) {
    _dismissSurface = connection.compositor.createSurface().getOrElse((e) {
      stderr.writeln('[network] dismiss surface: $e');
      return WlSurface(connection.context);
    });
    _dismissLayer = shell
        .getLayerSurface(
          _dismissSurface!,
          connection.output,
          LayerShellV1Layer.overlay.enumValue,
          'bardash-network-dismiss',
        )
        .getOrElse((e) {
      stderr.writeln('[network] dismiss layer: $e');
      return LayerSurfaceV1(connection.context);
    });

    _dismissLayer!.setAnchor(LayerSurfaceV1Anchor.top.enumValue |
        LayerSurfaceV1Anchor.bottom.enumValue |
        LayerSurfaceV1Anchor.left.enumValue |
        LayerSurfaceV1Anchor.right.enumValue);
    if (openUpward) {
      _dismissLayer!.setMargin(0, 0, parentHeight, 0);
    } else {
      _dismissLayer!.setMargin(parentHeight, 0, 0, 0);
    }
    _dismissLayer!.setSize(0, 0);
    _dismissLayer!.setExclusiveZone(-1);
    _dismissLayer!.setKeyboardInteractivity(
        LayerSurfaceV1KeyboardInteractivity.none.enumValue);
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

  Future<bool> _waitConfigureAsync() async {
    final done = dart_async.Completer<void>();
    var sawLayer = false;
    var sawDismiss = false;
    void tryComplete() {
      if (sawLayer && sawDismiss && !done.isCompleted) done.complete();
    }

    _layer!.onConfigure((e) {
      _layer!.ackConfigure(e.serial);
      sawLayer = true;
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
    } on dart_async.TimeoutException {
      return false;
    }
  }

  void _mapLayer() {
    final stride = _w * 4;
    final slotSize = stride * _h;
    for (var i = 0; i < 2; i++) {
      final fd = createAnonymousFile(slotSize);
      if (fd < 0) return;
      _fds[i] = fd;
      final pool = connection.shm.createPool(fd, slotSize).getOrElse((e) {
        stderr.writeln('[network] pool $i: $e');
        return WlShmPool(connection.context);
      });
      _pools[i] = pool;
      final buf = pool.createBuffer(0, _w, _h, stride, 0).getOrElse((e) {
        stderr.writeln('[network] buffer $i: $e');
        return WlBuffer(connection.context);
      });
      final slot = i;
      buf.onRelease((_) {
        _busy[slot] = false;
        if (_needsPaint && _open) _scheduleRepaint();
      });
      _buffers[i] = buf;
      _busy[i] = false;
    }
    _front = 0;
    _needsPaint = false;
    _paintScheduled = false;
    _presenting = false;
    _present();
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
    _dismissPool = connection.shm.createPool(_dismissFd, size).getOrElse((e) {
      stderr.writeln('[network] dismiss pool: $e');
      return WlShmPool(connection.context);
    });
    _dismissBuffer =
        _dismissPool!.createBuffer(0, w, h, stride, 0).getOrElse((e) {
      stderr.writeln('[network] dismiss buffer: $e');
      return WlBuffer(connection.context);
    });
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

  void _scheduleRepaint() {
    _needsPaint = true;
    if (_paintScheduled) return;
    _paintScheduled = true;
    dart_async.scheduleMicrotask(() {
      _paintScheduled = false;
      if (!_open || !_needsPaint) return;
      _present();
    });
  }

  void _present() {
    if (_surface == null || _presenting) {
      _needsPaint = true;
      return;
    }
    _presenting = true;
    try {
      var slot = 1 - _front;
      if (_busy[slot] || _buffers[slot] == null) slot = _front;
      if (_busy[slot] || _buffers[slot] == null || _fds[slot] < 0) {
        _needsPaint = true;
        return;
      }
      _paintInto(_fds[slot]);
      _busy[slot] = true;
      _front = slot;
      _needsPaint = false;
      _surface!.attach(_buffers[slot]!, 0, 0);
      _surface!.damage(0, 0, _w, _h);
      _surface!.commit();
    } finally {
      _presenting = false;
    }
  }

  void _paintInto(int fd) {
    if (fd < 0) return;
    final painter = SkiaPainter(fd, _w, _h);
    try {
      painter.clear(_bg);
      painter.drawRRect(
        Rect.fromLTWH(0, 0, _w.toDouble(), _h.toDouble()),
        10,
        10,
        Paint()..color = _bg,
      );
      painter.drawRect(
        Rect.fromLTWH(0.5, 0.5, _w - 1.0, _h - 1.0),
        Paint()
          ..color = _border
          ..style = PaintStyle.stroke
          ..strokeWidth = 1,
      );

      final snap = NetworkManagerClient.instance.last;
      final ssid = snap.ssid.isNotEmpty ? snap.ssid : snap.connectionId;
      final title = ssid.isEmpty ? 'Network' : ssid;
      final iconGlyph = snap.type == 'ethernet' ? '󰈀' : '󰖩';
      final lw = 12.0;

      // Title row: icon + name.
      final iconW = painter.measureTextBounds(iconGlyph, size: 18, fontFamily: 'sans').width;
      painter.drawText(
        iconGlyph,
        Offset(NetworkPanelLayout.pad.toDouble(), 14),
        color: _icon,
        size: 18,
      );
      final titleB = painter.measureTextBounds(title, size: 15, fontFamily: 'sans');
      painter.drawText(
        title,
        Offset(NetworkPanelLayout.pad + iconW + 6, TextLayout.baselineForBounds(14, 18, titleB)),
        color: _text,
        size: 15,
      );

      // Divider.
      painter.drawRect(
        Rect.fromLTWH(NetworkPanelLayout.pad.toDouble(), 36, _w - NetworkPanelLayout.pad * 2, 1),
        Paint()..color = _sep,
      );

      // Info rows (centered via baseline).
      final rows = <(String, String, Color)>[
        ('Interface', snap.ifname.isEmpty ? '—' : snap.ifname, _dim),
        ('IP', snap.ip4.isEmpty ? '—' : snap.ip4, _text),
        if (snap.signal >= 0) ('Signal', '${snap.signal}%', _text),
        ('↓', NetSpeed.formatRate(NetSpeed.downBps), _down),
        ('↑', NetSpeed.formatRate(NetSpeed.upBps), _up),
      ];
      for (var i = 0; i < rows.length; i++) {
        final y = 48 + i * NetworkPanelLayout.rowH;
        final (label, value, valueColor) = rows[i];
        final labelBase = TextLayout.baselineForBounds(y.toDouble(), 14, painter.measureTextBounds(label, size: lw, fontFamily: 'sans'));
        painter.drawText(label, Offset(NetworkPanelLayout.pad.toDouble(), labelBase), color: _dim, size: lw);
        final vBase = TextLayout.baselineForBounds(y.toDouble(), 14, painter.measureTextBounds(value, size: lw, fontFamily: 'sans'));
        painter.drawText(value, Offset(_w - NetworkPanelLayout.pad - painter.measureTextBounds(value, size: lw, fontFamily: 'sans').width, vBase), color: valueColor, size: lw);
      }

      // Divider + action row.
      painter.drawRect(
        Rect.fromLTWH(NetworkPanelLayout.pad.toDouble(), 152, _w - NetworkPanelLayout.pad * 2, 1),
        Paint()..color = _sep,
      );
      final bTop = (_h - NetworkPanelLayout.pad - NetworkPanelLayout.btnH).toDouble();
      final bH = NetworkPanelLayout.btnH.toDouble();
      final openBtn = _layout.btnSpeedTest();
      painter.drawRRect(openBtn, 8, 8, Paint()..color = _btn);
      final openLabel = 'Speed Test';
      final openB = painter.measureTextBounds(openLabel, size: lw, fontFamily: 'sans');
      painter.drawText(openLabel, Offset(openBtn.left + 10, TextLayout.baselineForBounds(bTop, bH, openB)), color: _text, size: lw);

      final setBtn = _layout.btnSettings();
      painter.drawRRect(setBtn, 8, 8, Paint()..color = _btnHover);
      final setLabel = 'Settings';
      final setB = painter.measureTextBounds(setLabel, size: lw, fontFamily: 'sans');
      painter.drawText(setLabel, Offset(setBtn.left + 10, TextLayout.baselineForBounds(bTop, bH, setB)), color: _text, size: lw);

      painter.flush();
    } finally {
      painter.dispose();
    }
  }

  void _teardown() {
    _needsPaint = false;
    _paintScheduled = false;
    _presenting = false;
    for (var i = 0; i < 2; i++) {
      _buffers[i]?.destroy();
      _buffers[i] = null;
      _pools[i]?.destroy();
      _pools[i] = null;
      if (_fds[i] >= 0) {
        closeFd(_fds[i]);
        _fds[i] = -1;
      }
      _busy[i] = false;
    }
    _front = 0;
    _layer?.destroy();
    _layer = null;
    _surface?.destroy();
    _surface = null;

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
