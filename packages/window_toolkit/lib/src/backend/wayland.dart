import 'dart:io';

import 'package:wayland/wayland.dart';

import '../app.dart';
import '../drawing/canvas.dart';
import '../widget.dart';
import '../mixins/event.dart';
import '../mixins/size.dart';
import '../painter/painter.dart' hide Size;
import '../painter/raw_painter.dart';
import '../painter/skia_painter.dart';
import 'backend.dart';
import 'connection.dart';

class WaylandBackend with Size, Events implements Backend {
  @override
  final WaylandConnection connection = Application.instance.connection;
  @override
  VoidCallback? onFrameReady;
  late Context context;
  late WlDisplay display;
  late WlRegistry registry;
  late WlCompositor compositor;
  late WlShm shm;
  late WlSeat seat;
  late XdgWmBase xdgWmBase;
  late WlSurface surface;
  late XdgSurface xdgSurface;
  late XdgToplevel xdgToplevel;

  WlShmPool? _pool;
  int _poolSize = 0;
  int _fd = -1;
  WlBuffer? _buffer;
  bool _bufferBusy = false;

  bool _running = false;
  bool _needsPaint = false;

  Function()? onReady;
  void Function(int width, int height)? onConfigure;
  Function()? onClose;

  @override
  bool get isRunning => _running;

  @override
  bool get canPaint => !_bufferBusy;

  Future<void> init() async {
    await connection.connect();

    context = connection.context;
    display = connection.display;
    registry = connection.registry;
    compositor = connection.compositor;
    shm = connection.shm;
    seat = connection.seat;
    xdgWmBase = connection.xdgWmBase;

    _setupSurface();
    onReady?.call();
  }

  void _setupSurface() {
    surface = compositor.createSurface().getOrElse((e) {
      stderr.writeln('[wt] createSurface failed: $e');
      return WlSurface(context);
    });

    xdgSurface = xdgWmBase.getXdgSurface(surface).getOrElse((e) {
      stderr.writeln('[wt] getXdgSurface failed: $e');
      return XdgSurface(context);
    });

    xdgSurface.onConfigure((e) {
      xdgSurface.ackConfigure(e.serial);
      if (width > 0 && height > 0) {
        _ensureBuffer();
        onConfigure?.call(width, height);
      } else {
        stderr.writeln('[wt] surf cfg skip w=$width h=$height');
        surface.commit();
      }
    });

    xdgToplevel = xdgSurface.getToplevel().getOrElse((e) {
      stderr.writeln('[wt] getToplevel failed: $e');
      return XdgToplevel(context);
    });

    xdgToplevel.onConfigure((e) {
      final newW = e.width != 0 ? e.width : (width == 0 ? 800 : width);
      final newH = e.height != 0 ? e.height : (height == 0 ? 600 : height);
      stderr.writeln('[wt] toplevel cfg w=${e.width} h=${e.height} -> ${newW}x$newH (cur ${width}x$height) invalidate=${newW!=width||newH!=height} busy=$_bufferBusy pool=$_pool');
      if (newW != width || newH != height) {
        width = newW;
        height = newH;
        _invalidateBuffer();
      }
    });

    xdgToplevel.onClose((_) {
      _running = false;
      onClose?.call();
    });

    xdgToplevel.setTitle('window-toolkit');
    xdgToplevel.setAppId('window-toolkit');
    surface.commit();
  }

  void _ensureBuffer() {
    final stride = width * 4;
    final size = stride * height;

    if (size <= 0) { stderr.writeln('[wt] ensureBuffer skip size=$size'); return; }
    if (_pool != null && size <= _poolSize) return;

    _pool?.destroy();
    closeFd(_fd);
    _fd = createAnonymousFile(size);
    _pool = shm.createPool(_fd, size).getOrElse((e) {
      stderr.writeln('[wt] createPool failed: $e');
      return WlShmPool(context);
    });
    _poolSize = size;

    _buffer?.destroy();
    _buffer = _pool!.createBuffer(0, width, height, stride, 0).getOrElse((e) {
      stderr.writeln('[wt] createBuffer failed: $e');
      return WlBuffer(context);
    });
    _buffer!.onRelease((_) {
      _bufferBusy = false;
      if (_needsPaint) {
        _needsPaint = false;
        onFrameReady?.call();
      }
    });
  }

  void _invalidateBuffer() {
    stderr.writeln('[wt] invalidate pool=$_pool buf=$_buffer fd=$_fd w=${width}x$height');
    _buffer?.destroy();
    _buffer = null;
    _pool?.destroy();
    _pool = null;
    _poolSize = 0;
    closeFd(_fd);
    _fd = -1;
    _needsPaint = true;
  }

  void paintTo(Canvas canvas) {
    _ensureBuffer();
    writeToFd(_fd, canvas.pixels);
    _needsPaint = false;
    _present();
  }

  bool _present() {
    if (_buffer == null) { stderr.writeln('[wt] present skip — no buffer'); return false; }
    if (_bufferBusy) { stderr.writeln('[wt] present skip — buffer busy'); return false; }
    if (_bufferBusy || _buffer == null) return false;

    _bufferBusy = true;
    surface.attach(_buffer!, 0, 0);
    surface.damageBuffer(0, 0, width, height);

    // Use the frame callback to trigger the next paint when the
    // compositor is ready, in case the buffer release callback
    // never fires (e.g. during compositor state transitions).
    final frameResult = surface.frame();
    frameResult
        .getOrElse((e) {
          stderr.writeln('[wt] frame() failed: $e');
          return WlCallback(context);
        })
        .onDone((_) {
          // Frame callback fired — compositor is ready for next frame.
          // If we have a pending paint, fire it now.
          if (_needsPaint) {
            _needsPaint = false;
            onFrameReady?.call();
          }
        });
    surface.commit();
    return true;
  }

  void requestPaint() {
    if (_bufferBusy) {
      _needsPaint = true;
      return;
    }
    _present();
  }

  @override
  void start() {
    _running = true;
  }

  @override
  void dispatchEvents() {
    connection.dispatch();
  }

  @override
  Painter createPainter(int width, int height) {
    _ensureBuffer();
    try {
      return SkiaPainter(_fd, width, height);
    } catch (e) {
      stderr.writeln(
        '[wt] SkiaPainter unavailable, falling back to RawPainter: $e',
      );
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
    if (!_present()) {
      stderr.writeln('[wt] paint deferred — present failed');
      _needsPaint = true;
    } else {
      stderr.writeln('[wt] paint ok buf=$_buffer busy=$_bufferBusy');
    }
  }

  @override
  void destroy() {
    _buffer?.destroy();
    _pool?.destroy();
    closeFd(_fd);
    _running = false;
  }
}
