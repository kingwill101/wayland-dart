import 'dart:io';

import 'package:wayland/wayland.dart';

import '../painter/painter.dart' hide Size;
import '../painter/raw_painter.dart';
import '../painter/skia_painter.dart';
import '../platform/platform.dart';
import '../widget.dart';
import 'backend.dart';
import 'connection.dart';
import 'wayland_surface.dart';

class PopupBackend implements Backend {
  final WaylandConnection connection;
  late final WaylandSurface _platformSurface;
  final XdgSurface parentSurface;
  int _width = 0;
  int _height = 0;
  bool _running = false;

  late WlSurface wlSurface;
  late XdgSurface xdgSurface;
  late XdgPopup popup;

  @override
  PlatformConnection get platformConnection => connection;

  @override
  PlatformSurface get platformSurface => _platformSurface;

  WlShmPool? _pool;
  int _poolSize = 0;
  int _fd = -1;
  WlBuffer? _buffer;
  bool _bufferBusy = false;
  bool _needsPaint = false;

  @override
  VoidCallback? onFrameReady;

  /// Called when the popup is dismissed (popup_done event).
  VoidCallback? onDismiss;

  PopupBackend({
    required this.connection,
    required this.parentSurface,
    int width = 200,
    int height = 300,
    int anchorX = 0,
    int anchorY = 0,
    int anchorWidth = 0,
    int anchorHeight = 0,
  }) {
    _width = width;
    _height = height;
    _setup(anchorX, anchorY, anchorWidth, anchorHeight);
  }

  void _setup(int ax, int ay, int aw, int ah) {
    final ctx = connection.context;
    final compositor = connection.compositor;
    final wmBase = connection.xdgWmBase;

    wlSurface = compositor.createSurface().getOrElse((e) {
      stderr.writeln('[popup] createSurface failed: $e');
      return WlSurface(ctx);
    });
    _platformSurface = WaylandSurface(connection, wlSurface);

    xdgSurface = wmBase.getXdgSurface(wlSurface).getOrElse((e) {
      stderr.writeln('[popup] getXdgSurface failed: $e');
      return XdgSurface(ctx);
    });

    final positioner = wmBase.createPositioner().getOrElse((e) {
      stderr.writeln('[popup] createPositioner failed: $e');
      return XdgPositioner(ctx);
    });

    positioner.setSize(_width, _height);
    positioner.setAnchorRect(ax, ay, aw, ah);
    positioner.setAnchor(XdgPositionerAnchor.topLeft.enumValue);
    positioner.setGravity(XdgPositionerGravity.bottomRight.enumValue);
    positioner.setOffset(0, 0);
    positioner.setReactive();

    popup = xdgSurface.getPopup(parentSurface, positioner).getOrElse((e) {
      stderr.writeln('[popup] getPopup failed: $e');
      return XdgPopup(ctx);
    });

    popup.onConfigure((e) {
      if (e.width > 0 && e.height > 0) {
        _width = e.width;
        _height = e.height;
        _ensureBuffer();
      }
    });

    popup.onPopupDone((_) {
      _running = false;
      onDismiss?.call();
    });

    _platformSurface.commit();
  }

  @override
  bool get isRunning => _running;

  @override
  int get width => _width;
  @override
  set width(int value) => _width = value;

  @override
  int get height => _height;
  @override
  set height(int value) => _height = value;

  @override
  bool get canPaint => !_bufferBusy && platformConnection.isConnected;

  @override
  void requestPaint() {
    if (_bufferBusy) {
      _needsPaint = true;
      return;
    }
    _present();
  }

  void _ensureBuffer() {
    final stride = _width * 4;
    final size = stride * _height;
    if (_pool != null && size <= _poolSize) return;

    _pool?.destroy();
    closeFd(_fd);
    _fd = createAnonymousFile(size);
    _pool = connection.shm.createPool(_fd, size).getOrElse((e) {
      stderr.writeln('[popup] createPool failed: $e');
      return WlShmPool(connection.context);
    });
    _poolSize = size;

    _buffer?.destroy();
    _buffer = _pool!.createBuffer(0, _width, _height, stride, 0).getOrElse((e) {
      stderr.writeln('[popup] createBuffer failed: $e');
      return WlBuffer(connection.context);
    });
    _buffer!.onRelease((_) {
      _bufferBusy = false;
      if (_needsPaint) {
        _needsPaint = false;
        onFrameReady?.call();
      }
    });
  }

  bool _present() {
    if (_bufferBusy || _buffer == null) return false;
    _bufferBusy = true;
    wlSurface.attach(_buffer!, 0, 0);
    wlSurface.damageBuffer(0, 0, _width, _height);
    _platformSurface.commit();
    return true;
  }

  @override
  Painter createPainter(int width, int height) {
    _ensureBuffer();
    try {
      return SkiaPainter(_fd, width, height);
    } catch (e) {
      stderr.writeln('[popup] SkiaPainter unavailable: $e');
      return RawPainter(_fd, width, height);
    }
  }

  @override
  void paintWithPainter(Painter painter) {
    if (painter is SkiaPainter) {
      painter.flush();
    } else if (painter is RawPainter) {
      painter.flush();
    }
    if (!_present()) _needsPaint = true;
  }

  @override
  void dispatchEvents() => platformConnection.dispatch();

  @override
  Future<void> init() async {}

  @override
  void start() {
    _running = true;
  }

  @override
  void destroy() {
    _buffer?.destroy();
    _pool?.destroy();
    _platformSurface.destroy();
    closeFd(_fd);
    _running = false;
  }

  @override
  void Function(int width, int height)? get onConfigure => null;
  @override
  set onConfigure(void Function(int width, int height)? callback) {}
  @override
  Function()? get onClose => onDismiss;
  @override
  set onClose(Function()? callback) {
    onDismiss = callback;
  }
}
