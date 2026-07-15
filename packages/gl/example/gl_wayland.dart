/// OpenGL ES 2.0 rendering into a Wayland window.
///
/// Uses the high-level GL wrapper — no manual FFI memory management.
/// Renders a rotating triangle fan, reads pixels back via GL.readPixelsAll(),
/// and ships them to the compositor through a shared memory buffer.
///
/// Usage: run under a Wayland compositor (sway, Hyprland, river, …).
library;

import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:gl/gl.dart';
import 'package:wayland/wayland.dart';

void main() async {
  final app = GlesWaylandApp();
  await app.init();
  app.run();
}

class GlesWaylandApp {
  // ── GL state ───────────────────────────────────────────────────
  late GL gl;
  late Program program;
  late int aPos;
  late int uColor;
  double _rotation = 0;

  // ── Wayland state ──────────────────────────────────────────────
  late Context context;
  late WlDisplay display;
  late WlRegistry registry;
  late WlCompositor compositor;
  late WlShm shm;
  late XdgWmBase xdgWmBase;
  late WlSurface wlSurface;
  late XdgSurface xdgSurface;
  late XdgToplevel toplevel;
  int width = 800;
  int height = 600;
  bool running = true;

  // ── SHM pool ───────────────────────────────────────────────────
  WlShmPool? _pool;
  int _poolSize = 0;
  int _fd = -1;

  Future<void> init() async {
    _initGl();
    _initWayland();
    stderr.writeln('[gl] ready — close the window to exit');
  }

  void _initGl() {
    // Create EGL context + PBuffer (offscreen).
    gl = GL.create(width: width, height: height);

    // Build shaders.
    final vs = Shader.vertex(
      'attribute vec2 aPos;'
      'void main() { gl_Position = vec4(aPos, 0.0, 1.0); }',
    );
    final fs = Shader.fragment(
      'precision mediump float;'
      'uniform vec4 uColor;'
      'void main() { gl_FragColor = uColor; }',
    );

    program = Program()
      ..attach(vs)
      ..attach(fs)
      ..link()
      ..use();

    aPos = program.getAttribLocation('aPos');
    uColor = program.getUniformLocation('uColor');
  }

  void _initWayland() {
    context = Context();
    context.connect();

    display = WlDisplay(context);
    display.onError((e) { stderr.writeln('[gl] display error: $e'); running = false; });

    registry = display.getRegistry().getOrElse((e) { _fail('getRegistry'); });
    registry.onGlobal(_onGlobal);
    _roundtrip();
    _roundtrip();

    wlSurface = compositor.createSurface().getOrElse((e) { _fail('createSurface'); });
    xdgSurface = xdgWmBase.getXdgSurface(wlSurface).getOrElse((e) { _fail('getXdgSurface'); });
    xdgSurface.onConfigure((e) {
      xdgSurface.ackConfigure(e.serial);
      _renderAndPresent();
      wlSurface.commit();
      _requestNextFrame();
    });
    toplevel = xdgSurface.getToplevel().getOrElse((e) { _fail('getToplevel'); });
    toplevel.onConfigure((e) {
      if (e.width > 0 && e.height > 0) { width = e.width; height = e.height; }
    });
    toplevel.onClose((_) { running = false; });
    toplevel.setTitle('GLES2 Wayland');
    toplevel.setAppId('gl-wayland');
    wlSurface.commit();
  }

  void _requestNextFrame() {
    final cb = wlSurface.frame().getOrElse((_) => WlCallback(context));
    cb.onDone((_) {
      if (!running) return;
      _renderAndPresent();
      wlSurface.commit();
      _requestNextFrame();
    });
  }

  void _onGlobal(dynamic global) {
    switch (global.interface) {
      case 'wl_compositor':
        compositor = WlCompositor(context);
        registry.bind(global.name, global.interface, global.version, compositor.objectId);
      case 'wl_shm':
        shm = WlShm(context);
        registry.bind(global.name, global.interface, global.version, shm.objectId);
      case 'xdg_wm_base':
        xdgWmBase = XdgWmBase(context);
        xdgWmBase.onPing((p) => xdgWmBase.pong(p.serial));
        registry.bind(global.name, global.interface, global.version, xdgWmBase.objectId);
    }
  }

  void _roundtrip() {
    final cb = display.sync().getOrElse((_) => WlCallback(context));
    var done = false;
    cb.onDone((_) { done = true; });
    while (!done) { context.dispatch(); }
  }

  void run() {
    while (running) { context.dispatch(); }
    _cleanup();
  }

  void _renderAndPresent() {
    // Update rotation.
    _rotation += 0.025;
    if (_rotation > 2 * pi) _rotation -= 2 * pi;

    // Resize GL surface if window size changed.
    if (gl.width != width || gl.height != height) {
      gl.resize(width, height);
    }

    gl.makeCurrent();
    gl.viewport(0, 0, width, height);
    gl.clearColor(0.08, 0.08, 0.12, 1.0);
    gl.clear();

    // Draw three overlapping coloured triangles.
    program.use();
    final colours = [
      [1.0, 0.2, 0.2],
      [0.2, 1.0, 0.2],
      [0.2, 0.4, 1.0],
    ];

    for (var i = 0; i < 3; i++) {
      final angle = i * 2 * pi / 3 + _rotation;
      final verts = Float32List.fromList([
        0.0, 0.0,
        cos(angle) * 0.7, sin(angle) * 0.7,
        cos(angle + 2 * pi / 3) * 0.7, sin(angle + 2 * pi / 3) * 0.7,
      ]);

      final vbo = VertexBuffer()
        ..setData(verts)
        ..bind()
        ..attribPointer(aPos, 2, GL_FLOAT, false, 0, 0)
        ..enable(aPos);

      gl.uniform4f(uColor, colours[i][0], colours[i][1], colours[i][2], 1.0);
      gl.drawArrays(GL_TRIANGLES, 0, 3);

      vbo.dispose();
    }

    // Read pixels and write to SHM.
    final pixels = gl.readPixelsAll();
    _present(pixels);
  }

  void _present(Uint8List pixels) {
    final stride = width * 4;
    final size = stride * height;

    if (_pool == null || size > _poolSize) {
      _pool?.destroy();
      closeFd(_fd);
      _fd = createAnonymousFile(size);
      _pool = shm.createPool(_fd, size).getOrElse((e) {
        stderr.writeln('[gl] createPool failed: $e');
        return WlShmPool(context);
      });
      _poolSize = size;
    }

    final buffer = _pool!.createBuffer(0, width, height, stride, 0).getOrElse((e) {
      stderr.writeln('[gl] createBuffer failed: $e');
      return WlBuffer(context);
    });
    buffer.onRelease((_) => buffer.destroy());

    writeToFd(_fd, pixels);
    wlSurface.attach(buffer, 0, 0);
    wlSurface.damageBuffer(0, 0, width, height);
  }

  void _cleanup() {
    stderr.writeln('[gl] shutting down');
    _pool?.destroy();
    closeFd(_fd);
    program.dispose();
    gl.dispose();
    context.close();
  }

  Never _fail(String msg) {
    stderr.writeln('[gl] ERROR: $msg');
    exit(1);
  }
}
