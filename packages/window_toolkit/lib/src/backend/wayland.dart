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
  bool _bufferNeedsRecreate = false;

  bool _running = false;
  bool _needsPaint = false;

  Function()? onReady;
  @override
  void Function(int width, int height)? onConfigure;
  @override
  Function()? onClose;

  @override
  bool get isRunning => _running;

  @override
  bool get canPaint => !_bufferBusy && connection.isConnected;

  @override
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
      stderr.writeln(
        '[wt:xdg] surface configure serial=${e.serial} size=${width}x$height',
      );
      xdgSurface.ackConfigure(e.serial);
      if (width > 0 && height > 0) {
        _ensureBuffer();
        onConfigure?.call(width, height);
      } else {
        surface.commit();
      }
    });

    xdgToplevel = xdgSurface.getToplevel().getOrElse((e) {
      stderr.writeln('[wt] getToplevel failed: $e');
      return XdgToplevel(context);
    });

    xdgToplevel.onConfigure((e) {
      stderr.writeln(
        '[wt:xdg] toplevel configure ${e.width}x${e.height} '
        '(current ${width}x$height)',
      );
      final newW = e.width != 0 ? e.width : (width == 0 ? 800 : width);
      final newH = e.height != 0 ? e.height : (height == 0 ? 600 : height);
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

    if (size <= 0) return;

    // Reuse a pool for same-sized frames, but swap pools for a larger
    // configure. Hyprland accepts wl_shm_pool.resize, yet can reject a buffer
    // created immediately after that request while remapping the pool.
    if (_pool != null) {
      if (size <= _poolSize) {
        if (_buffer != null || _bufferBusy) return;
        _createBuffer(stride);
        return;
      }
      if (_bufferBusy) return;

      final oldPool = _pool;
      final oldBuffer = _buffer;
      final oldFd = _fd;
      final oldPoolSize = _poolSize;
      _pool = null;
      _buffer = null;
      _poolSize = 0;
      _fd = -1;

      stderr.writeln(
        '[wt:shm] replacing pool $oldPoolSize -> $size '
        'stride=$stride dimensions=${width}x$height',
      );
      _fd = createAnonymousFile(size);
      if (_fd < 0) {
        throw StateError('[wt:shm] failed to create ${size}B anonymous file');
      }
      stderr.writeln('[wt:shm] created fd=$_fd size=$size');
      _pool = shm.createPool(_fd, size).getOrElse((e) {
        stderr.writeln('[wt] createPool failed: $e');
        return WlShmPool(context);
      });
      _poolSize = size;
      _createBuffer(stride);

      // Queue the new pool/buffer before retiring the old pool. This keeps an
      // in-flight buffer from invalidating create_pool.
      oldBuffer?.destroy();
      oldPool?.destroy();
      closeFd(oldFd);
      return;
    }

    stderr.writeln(
      '[wt:shm] allocating pool size=$size stride=$stride '
      'dimensions=${width}x$height oldPool=$_poolSize oldFd=$_fd',
    );
    _fd = createAnonymousFile(size);
    if (_fd < 0) {
      throw StateError('[wt:shm] failed to create ${size}B anonymous file');
    }
    stderr.writeln('[wt:shm] created fd=$_fd size=$size');
    _pool = shm.createPool(_fd, size).getOrElse((e) {
      stderr.writeln('[wt] createPool failed: $e');
      return WlShmPool(context);
    });
    _poolSize = size;

    _createBuffer(stride);
  }

  void _createBuffer(int stride) {
    if (_buffer != null || _bufferBusy) return;
    _buffer = _pool!.createBuffer(0, width, height, stride, 0).getOrElse((e) {
      stderr.writeln('[wt] createBuffer failed: $e');
      return WlBuffer(context);
    });
    _buffer!.onRelease((_) {
      _bufferBusy = false;
      if (_bufferNeedsRecreate) {
        _bufferNeedsRecreate = false;
        _buffer?.destroy();
        _buffer = null;
      }
      if (_needsPaint) {
        _needsPaint = false;
        onFrameReady?.call();
      }
    });
  }

  void _invalidateBuffer() {
    _needsPaint = true;
    // A wl_buffer may still be owned by the compositor when a configure
    // arrives. Keep it alive until release; destroying it here leaves the
    // backend permanently busy and causes an endless deferred-paint loop.
    if (_bufferBusy) {
      _bufferNeedsRecreate = true;
      return;
    }
    _buffer?.destroy();
    _buffer = null;
  }

  void paintTo(Canvas canvas) {
    _ensureBuffer();
    writeToFd(_fd, canvas.pixels);
    _needsPaint = false;
    _present();
  }

  bool _present() {
    if (_bufferBusy || _buffer == null) return false;

    _bufferBusy = true;
    surface.attach(_buffer!, 0, 0);
    surface.damageBuffer(0, 0, width, height);

    final frameResult = surface.frame();
    frameResult
        .getOrElse((e) {
          stderr.writeln('[wt] frame() failed: $e');
          return WlCallback(context);
        })
        .onDone((_) {
          if (_needsPaint) {
            _needsPaint = false;
            onFrameReady?.call();
          }
        });
    surface.commit();
    return true;
  }

  @override
  void requestPaint() {
    if (!connection.isConnected) return;
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
      _needsPaint = true;
    }
  }

  @override
  void destroy() {
    _buffer?.destroy();
    _pool?.destroy();
    closeFd(_fd);
    _buffer = null;
    _bufferNeedsRecreate = false;
    _pool = null;
    _fd = -1;
    _running = false;
  }
}
