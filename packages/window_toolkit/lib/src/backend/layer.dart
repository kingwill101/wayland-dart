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
      if (e.width > 0 && e.height > 0) {
        width = e.width;
        height = e.height;
        _ensureBuffer();
        onConfigure?.call(width, height);
      } else {
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

    if (_pool != null && size <= _poolSize) return;

    // Guard against zero-size buffers (not-yet-configured dimensions).
    if (size <= 0) {
      _pool?.destroy();
      _pool = null;
      _poolSize = 0;
      return;
    }

    _skia?.dispose();
    _skia = null;
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
    switch (b) {
      case RendererBackend.gl:
        return GlesPainter(_fd, width, height);
      case RendererBackend.skia:
        try {
          return SkiaPainter(_fd, width, height);
        } catch (e) {
          stderr.writeln('[wt] SkiaPainter unavailable, falling back to RawPainter: $e');
        }
        return RawPainter(_fd, width, height);
      case RendererBackend.auto:
        try {
          return GlesPainter(_fd, width, height);
        } catch (e) {
          stderr.writeln('[wt] GlesPainter unavailable: $e');
        }
        try {
          return SkiaPainter(_fd, width, height);
        } catch (e) {
          stderr.writeln('[wt] SkiaPainter unavailable, falling back to RawPainter: $e');
        }
        return RawPainter(_fd, width, height);
    }
  }

  @override
  void paintWithPainter(Painter painter) {
    painter.flush();
    if (!_present()) {
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
        .onDone((_) {});

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
