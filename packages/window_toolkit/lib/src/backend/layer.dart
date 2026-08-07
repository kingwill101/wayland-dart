import 'dart:io';

import 'package:wayland/wayland.dart';

import '../app.dart';
import '../drawing/canvas.dart';
import '../drawing/skia_renderer.dart';
import '../mixins/event.dart';
import '../mixins/size.dart';
import '../painter/painter.dart' hide Size;
import '../painter/gles_painter.dart';
import '../painter/raw_painter.dart';
import '../painter/skia_painter.dart';
import '../renderer.dart';
import '../widget.dart';
import '../window_behavior.dart';

import 'backend.dart';
import 'connection.dart';

enum Anchor { top, bottom, left, right }

class LayerBackend with Size, Events implements Backend {
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
  late WlOutput output;
  LayerShellV1 get layerShell => connection.layerShell!;
  late WlSurface surface;
  late LayerSurfaceV1 layerSurface;

  WlShmPool? _pool;
  int _poolSize = 0;
  int _fd = -1;

  /// The current SHM file descriptor, exposed for subclasses that override
  /// [createPainter] with a custom painter (e.g. [GlesPainter]).
  int get shmFd => _fd;
  WlBuffer? _buffer;
  bool _bufferBusy = false;

  bool _running = false;
  bool _needsPaint = false;
  SkiaRenderer? _skia;

  final Anchor anchor;
  final int barHeight;
  final int exclusiveZone;
  final String namespace;

  Function()? onReady;
  @override void Function(int width, int height)? onConfigure;
  @override Function()? onClose;

  @override
  bool get isRunning => _running;

  @override
  bool get canPaint => !_bufferBusy;

  LayerBackend({
    this.anchor = Anchor.top,
    this.barHeight = 30,
    this.exclusiveZone = 30,
    this.namespace = 'wayland-toolkit',
  });

  @override
  Future<void> init() async {
    await connection.connect();

    context = connection.context;
    display = connection.display;
    registry = connection.registry;
    compositor = connection.compositor;
    shm = connection.shm;
    seat = connection.seat;
    output = connection.output;

    if (connection.layerShell == null) {
      stderr.writeln('[wt] zwlr_layer_shell_v1 not available');
      return;
    }

    _setupSurface();
    onReady?.call();
  }

  int _anchorToInt() {
    int a = 0;
    if (anchor == Anchor.top) a |= 1;
    if (anchor == Anchor.bottom) a |= 2;
    if (anchor == Anchor.left) a |= 4;
    if (anchor == Anchor.right) a |= 8;

    // For top/bottom bars, auto-add left+right to stretch full width
    if (anchor == Anchor.top || anchor == Anchor.bottom) {
      a |= 4 | 8; // left | right
    }
    // For left/right bars, auto-add top+bottom to stretch full height
    if (anchor == Anchor.left || anchor == Anchor.right) {
      a |= 1 | 2; // top | bottom
    }

    return a;
  }

  void _setupSurface() {
    surface = compositor.createSurface().getOrElse((e) {
      stderr.writeln('[wt] createSurface failed: $e');
      return WlSurface(context);
    });

    layerSurface = layerShell
        .getLayerSurface(
          surface,
          output,
          LayerShellV1Layer.top.enumValue,
          namespace,
        )
        .getOrElse((e) {
          stderr.writeln('[wt] getLayerSurface failed: $e');
          return LayerSurfaceV1(context);
        });

    layerSurface.setAnchor(_anchorToInt());
    layerSurface.setSize(0, barHeight);
    layerSurface.setExclusiveZone(exclusiveZone);

    layerSurface.onConfigure((e) {
      layerSurface.ackConfigure(e.serial);
      stderr.writeln('[wt:layer] configured: ${e.width}x${e.height}');
      if (e.width > 0 && e.height > 0) {
        width = e.width;
        height = e.height;
        stderr.writeln('[wt:layer] setting size $width x $height');
        _ensureBuffer();
        onConfigure?.call(width, height);
      } else {
        stderr.writeln('[wt:layer] configure with zero size, just committing');
        surface.commit();
      }
    });

    layerSurface.onClosed((_) {
      _running = false;
      onClose?.call();
    });

    surface.commit();
  }

  void _ensureBuffer() {
    final stride = width * 4;
    final size = stride * height;

    if (_pool != null && size <= _poolSize) {
      stderr.writeln('[wt:layer] _ensureBuffer: pool already sufficient (${_poolSize}B)');
      return;
    }

    // Guard against zero-size buffers (not-yet-configured dimensions).
    if (size <= 0) {
      stderr.writeln('[wt:layer] _ensureBuffer: size=$size (not configured yet), destroying pool');
      _pool?.destroy();
      _pool = null;
      _poolSize = 0;
      return;
    }

    stderr.writeln('[wt:layer] _ensureBuffer: allocating ${size}B buffer (${width}x$height)');
    _skia?.dispose();
    _skia = null;
    _pool?.destroy();
    closeFd(_fd);
    _fd = createAnonymousFile(size);
    stderr.writeln('[wt:layer] created anonymous file fd=$_fd size=$size');
    _pool = shm.createPool(_fd, size).getOrElse((e) {
      stderr.writeln('[wt:layer] createPool failed: $e');
      return WlShmPool(context);
    });
    _poolSize = size;

    _buffer?.destroy();
    _buffer = _pool!.createBuffer(0, width, height, stride, 0).getOrElse((e) {
      stderr.writeln('[wt:layer] createBuffer failed: $e');
      return WlBuffer(context);
    });
    _buffer!.onRelease((_) {
      stderr.writeln('[wt:layer] buffer released');
      _bufferBusy = false;
      if (_needsPaint) {
        stderr.writeln('[wt:layer] deferred paint after buffer release');
        _needsPaint = false;
        onFrameReady?.call();
      }
    });
    stderr.writeln('[wt:layer] buffer ready');
  }

  void paintTo(Canvas canvas) {
    _ensureBuffer();
    writeToFd(_fd, canvas.pixels);
    _needsPaint = false;
    _present();
  }

  @override
  Painter createPainter(int width, int height) {
    _ensureBuffer();
    // Backend selection from WindowBehavior mixin, or auto by default.
    final wb = (this is WindowBehavior) ? this as WindowBehavior : null;
    final b = wb?.rendererBackend ?? RendererBackend.auto;
    stderr.writeln('[wt:layer] createPainter($width, $height) backend=$b fd=$_fd');
    switch (b) {
      case RendererBackend.gl:
        try {
          return GlesPainter(_fd, width, height);
        } catch (e) {
          stderr.writeln('[wt:layer] GlesPainter failed: $e');
          rethrow;
        }
      case RendererBackend.skia:
        try {
          return SkiaPainter(_fd, width, height);
        } catch (e) {
          stderr.writeln('[wt:layer] SkiaPainter failed: $e');
          rethrow;
        }
      case RendererBackend.auto:
        try {
          stderr.writeln('[wt:layer] trying GlesPainter...');
          return GlesPainter(_fd, width, height);
        } catch (e) {
          stderr.writeln('[wt:layer] GlesPainter unavailable: $e');
        }
        try {
          stderr.writeln('[wt:layer] trying SkiaPainter...');
          return SkiaPainter(_fd, width, height);
        } catch (e) {
          stderr.writeln('[wt:layer] SkiaPainter unavailable: $e');
        }
        stderr.writeln('[wt:layer] falling back to RawPainter');
        return RawPainter(_fd, width, height);
    }
  }

  @override
  void paintWithPainter(Painter painter) {
    stderr.writeln('[wt:layer] paintWithPainter width=$width height=$height');
    painter.flush();
    if (!_present()) {
      stderr.writeln('[wt:layer] _present() returned false, scheduling retry');
      _needsPaint = true;
    }
  }

  void paintSkia(void Function(SkiaRenderer renderer) drawer) {
    _ensureBuffer();
    _skia ??= SkiaRenderer();
    _skia!.ensureBuffer(_fd, width, height);
    _skia!.canvas.save();
    drawer(_skia!);
    _skia!.canvas.restore();
    _skia!.flush();
    _needsPaint = false;
    _present();
  }

  bool _present() {
    if (_bufferBusy) {
      stderr.writeln('[wt:layer] _present: buffer busy, deferring');
      return false;
    }
    if (_buffer == null) {
      stderr.writeln('[wt:layer] _present: buffer is null!');
      _ensureBuffer();
      if (_buffer == null) {
        stderr.writeln('[wt:layer] _present: still null after _ensureBuffer!');
        return false;
      }
    }

    stderr.writeln('[wt:layer] presenting buffer $_buffer size=${width}x$height');
    _bufferBusy = true;
    surface.attach(_buffer!, 0, 0);
    surface.damageBuffer(0, 0, width, height);

    final frameResult = surface.frame();
    frameResult
        .getOrElse((e) {
          stderr.writeln('[wt:layer] frame() failed: $e');
          return WlCallback(context);
        })
        .onDone((_) {
          stderr.writeln('[wt:layer] frame callback done');
          if (_needsPaint) {
            _needsPaint = false;
            onFrameReady?.call();
          }
        });

    surface.commit();
    stderr.writeln('[wt:layer] surface committed');
    return true;
  }

  @override
  void requestPaint() {
    stderr.writeln('[wt:layer] requestPaint bufferBusy=$_bufferBusy');
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
  void destroy() {
    _skia?.dispose();
    _skia = null;
    _buffer?.destroy();
    _pool?.destroy();
    closeFd(_fd);
    _running = false;
  }
}
