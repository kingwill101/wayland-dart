import 'dart:io';
import 'dart:typed_data';

import 'package:wayland/wayland.dart';

void main() async {
  final app = WaylandApp();
  await app.init();
  app.run();
}

class WaylandApp {
  Context? context;
  WlDisplay? display;
  WlRegistry? registry;
  WlCompositor? compositor;
  WlShm? shm;
  WlSeat? seat;
  XdgWmBase? xdgWmBase;

  WlSurface? surface;
  XdgSurface? xdgSurface;
  XdgToplevel? xdgToplevel;

  int width = 800;
  int height = 600;
  bool running = true;

  WlShmPool? _pool;
  int _poolSize = 0;
  int _fd = -1;

  Future<void> init() async {
    context = Context();
    await context!.connect();

    display = WlDisplay(context!);
    display!.onError((e) {
      stderr.writeln('display error: $e');
      exit(1);
    });

    registry = display!.getRegistry().getOrElse((e) {
      stderr.writeln('getRegistry failed: $e');
      exit(1);
    });

    registry!.onGlobal(_onGlobal);
    registry!.onGlobalRemove((g) {});

    _roundtrip();
    _roundtrip();

    surface = compositor!.createSurface().getOrElse((e) {
      stderr.writeln('createSurface failed: $e');
      exit(1);
    });

    xdgSurface = xdgWmBase!.getXdgSurface(surface!).getOrElse((e) {
      stderr.writeln('getXdgSurface failed: $e');
      exit(1);
    });

    xdgSurface!.onConfigure((e) {
      xdgSurface!.ackConfigure(e.serial);
      _drawFrame();
      surface!.commit();
    });

    xdgToplevel = xdgSurface!.getToplevel().getOrElse((e) {
      stderr.writeln('getToplevel failed: $e');
      exit(1);
    });

    xdgToplevel!.onConfigure((e) {
      if (e.width != 0 && e.height != 0) {
        width = e.width;
        height = e.height;
      }
    });

    xdgToplevel!.onClose((_) {
      running = false;
    });
    xdgToplevel!.setTitle('Dart Wayland');
    xdgToplevel!.setAppId('dart-wayland');
    surface!.commit();
  }

  void run() {
    while (running) {
      context!.dispatch();
    }
    _cleanup();
    exit(0);
  }

  void _cleanup() {
    _pool?.destroy();
    _pool = null;
    closeFd(_fd);
    _fd = -1;
  }

  void _roundtrip() {
    final callback = display!.sync().getOrElse((e) {
      stderr.writeln('sync failed: $e');
      exit(1);
    });
    bool done = false;
    callback.onDone((_) {
      done = true;
    });
    while (!done) {
      context!.dispatch();
    }
  }

  void _onGlobal(dynamic global) {
    switch (global.interface) {
      case 'wl_compositor':
        compositor = WlCompositor(context!);
        registry!.bind(global.name, global.interface, global.version,
            compositor!.objectId);
      case 'wl_shm':
        shm = WlShm(context!);
        registry!.bind(
            global.name, global.interface, global.version, shm!.objectId);
      case 'wl_seat':
        seat = WlSeat(context!);
        registry!.bind(
            global.name, global.interface, global.version, seat!.objectId);
      case 'xdg_wm_base':
        xdgWmBase = XdgWmBase(context!);
        xdgWmBase!.onPing((p) => xdgWmBase!.pong(p.serial));
        registry!.bind(global.name, global.interface, global.version,
            xdgWmBase!.objectId);
    }
  }

  void _drawFrame() {
    final stride = width * 4;
    final size = stride * height;

    if (_pool == null || size > _poolSize) {
      _pool?.destroy();
      closeFd(_fd);
      _fd = createAnonymousFile(size);
      _pool = shm!.createPool(_fd, size).getOrElse((e) {
        stderr.writeln('createPool failed: $e');
        exit(1);
      });
      _poolSize = size;
    }

    final buffer = _pool!
        .createBuffer(0, width, height, stride, 0)
        .getOrElse((e) {
      stderr.writeln('createBuffer failed: $e');
      exit(1);
    });

    buffer.onRelease((_) => buffer.destroy());

    final data = Uint8List(size);
    final white = [0xFF, 0xFF, 0xFF, 0xFF];
    for (var i = 0; i < data.length; i += 4) {
      data.setRange(i, i + 4, white);
    }
    writeToFd(_fd, data);

    surface!.attach(buffer, 0, 0);
  }
}
