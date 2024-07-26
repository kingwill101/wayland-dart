import 'dart:io';
import 'dart:typed_data';

import 'package:wayland/protocols/stable/xdg-shell/xdg_shell.dart';
import 'package:wayland/protocols/wayland.dart';
import 'package:wayland/wayland.dart';

class App {
  Compositor? compositor;
  Registry? registry;
  Subcompositor? subCompositor;
  Shm? shm;
  Seat? seat;
  XdgWmBase? xdgWmBase;
  Display? display;
  Context? context;

  Surface? surface;

  XdgSurface? xdgSurface;

  XdgToplevel? xdgTopLevel;
  int width = 800;
  int height = 600;
  bool shouldExit = false;

  setExit() {
    shouldExit = true;
  }

  initWindow() async {
    context = Context();
    await context?.connect();

    var display = Display(context!);
    display.onError((a) {
      logLn("display.onerror: $a");
      exit(-1);
    });

    display.onDeleteId((a) {
      logLn("display.ondeleteId: $a");
    });

    registry = display.getRegistry().getOrElse((reg) {
      logLn("display.getRegistry: $reg");
      exit(-1);
    });

    registry?.onGlobal(registryGlobalHandler);
    registry?.onGlobalRemove((global) {
      logLn("global RRRRRRRRRRRR: $global");
    });
    roundTrip();
    roundTrip();

    surface = compositor?.createSurface().getOrElse((a) {
      logLn("createSurface failed: $a");
      exit(-1);
    });

    xdgSurface = xdgWmBase?.getXdgSurface(surface!).getOrElse((a) {
      logLn("xdgWmBase.getXdgSurface failed: $a");
      exit(-1);
    });
    xdgSurface?.onConfigure((con) {
      print("surface onConfigure $xdgSurface");
      xdgSurface?.ackConfigure(con.serial);
      final buffer = drawFrame();
      surface?.attach(buffer, 0, 0).onFailure((a) {
        logLn("surface.attach failed: $a");
      });
      surface?.commit().onFailure((a) {
        logLn("surface.commit failed: $a");
      });
    });

    xdgTopLevel = xdgSurface?.getToplevel().getOrElse((a) {
      logLn("xdgSurface.getToplevel failed: $a");
      exit(-1);
    });

    xdgTopLevel?.onConfigure((a) {
      logLn("xdgTopLevel onConfigure $xdgTopLevel");
      if (a.width != 0 && a.height != 0) {
        width = a.width;
        height = a.height;
      } else {
        return;
      }
    });

    xdgTopLevel?.onClose((a) {
      print("xdgTopLevel onClose $xdgTopLevel");
    });

    xdgTopLevel?.setTitle("Dart wayland");
    xdgTopLevel?.setAppId("dart-wayland");
    surface?.commit();
  }

  roundTrip() {
    var callback = display?.sync().getOrElse((a) {
      logLn("sync failed: $a");
      exit(-1);
    });

    callback?.onDone((val) {
      logLn("callback.ondone: $val\n");
    });

    dispatch();
  }

  dispatch() {
    context?.dispatch();
  }

  registryGlobalHandler(global) async {
    print("REGISTRY HANDLER");
    try {
      switch (global.interface) {
        case "wl_compositor":
          compositor = Compositor(context!);
          registry?.bind(global.name, global.interface, global.version,
              compositor!.objectId);
          break;
        case "wl_subcompositor":
          subCompositor = Subcompositor(context!);
          registry?.bind(global.name, global.interface, global.version,
              subCompositor!.objectId);
          break;
        case "wl_shm":
          shm = Shm(context!);
          shm?.onFormat((format) {
            logLn("shm format: $format");
          });
          registry?.bind(
              global.name, global.interface, global.version, shm!.objectId);
          break;
        case "wl_seat":
          seat = Seat(context!);
          seat?.onCapabilities((capa) {
            logLn("seat capabilities: $capa");
          });
          seat?.onName((name) {
            logLn("seat name: $name");
          });
          registry?.bind(
              global.name, global.interface, global.version, seat!.objectId);
          break;
        case "xdg_wm_base":
          xdgWmBase = XdgWmBase(context!);
          xdgWmBase?.onPing((ping) {
            logLn("xdg_wm_base ping: $ping");
            xdgWmBase?.pong(ping.serial);
            logLn("xdg_wm_base pong sent");
          });
          registry?.bind(global.name, global.interface, global.version,
              xdgWmBase!.objectId);
          break;
        default:
          break;
      }
    } catch (err) {
      logLn("unable to bind ${global.interface} interface: $err");
    }
  }

  Buffer drawFrame() {
    final stride = width * 4;
    final size = stride * height;

    final fd = createAnonymousFile(size);

    ShmPool pool = shm!.createPool(fd, size).getOrElse((a) {
      logLn("shm.createPool failed: $a");
      exit(-1);
    });

    final buffer = pool
        .createBuffer(0, width, height, stride, ShmFormat.argb8888.enumValue)
        .getOrElse((a) {
      logLn("pool.createBuffer failed: $a");
      exit(-1);
    });

    buffer.onRelease((releaseEvent) {
      print("buffer onRelease: $releaseEvent");
      buffer.destroy();
    });
    _paint(size, fd);
    logLn("Drawing frame complete");
    return buffer;
  }

  void _paint(int size, int fd) {
    final buffer = Uint8List.fromList(List.filled(size, 0xFF, growable: false));

    final whitePixel =
        Uint8List.fromList([0xFF, 0xFF, 0xFF, 0xFF]); // ARGB8888 white

    for (int i = 0; i < buffer.length; i += 4) {
      buffer.setRange(i, i + 4, whitePixel);
    }

    writeToFd(fd, buffer);
  }
}

void main() async {
  final app = App();
  await app.initWindow();
  while (!app.shouldExit) {
    app.dispatch();
  }
  exit(1);
}
