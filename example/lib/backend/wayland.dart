import 'dart:io';
import 'dart:isolate';

import 'package:example/backend/backend.dart';
import 'package:example/mixins/event.dart';
import 'package:example/modifier_keys.dart';
import 'package:wayland/protocols/stable/xdg-shell/xdg_shell.dart';
import 'package:wayland/protocols/wayland.dart';
import 'package:wayland/wayland.dart';

import '../drawing/drawing.dart';

class WaylandBackend extends Backend {
  Compositor? compositor;
  Registry? registry;
  Subcompositor? subCompositor;
  Shm? shm;
  Seat? seat;
  XdgWmBase? xdgWmBase;
  Context context = Context();
  Surface? surface;
  XdgSurface? xdgSurface;
  XdgToplevel? xdgTopLevel;
  int _bufferFd = -1;
  int _bufferSize = 0;
  Display? display;
  Pointer? pointer;
  Keyboard? keyboard;
  ModifierState _modifierState = ModifierState(
    modsDepressed: 0,
    modsLatched: 0,
    modsLocked: 0,
    group: 0,
  );

  double mouseX = 0;
  double mouseY = 0;

  Buffer? buffer;

  WaylandBackend([int width = 800, int height = 600]) {
    setDimensions(width, height);
    _init();
  }
  void _createDispatchIsolate() {
    ReceivePort receivePort = ReceivePort();
    receivePort.listen((v) {});
    Isolate.spawn(_dispatchLoop, receivePort.sendPort);
  }

  void _dispatchLoop(SendPort sendPort) {
    final receivePort = ReceivePort();
    sendPort.send(receivePort.sendPort);

    while (true) {
      dispatch();
    }
  }

  @override
  setTitle(String title) {
    super.setTitle(title);
    xdgTopLevel?.setTitle(this.title);
    surface?.commit();
  }

  _init() {
    display = Display(context);
    display?.onError(onDisplayError);

    display?.onDeleteId(onDisplayDeleteId);

    registry = display?.getRegistry().getOrNull();

    registry?.onGlobal(registryGlobalHandler);
    registry?.onGlobalRemove(onGlobalRemove);

    roundTrip();
    roundTrip();

    surface = compositor?.createSurface().getOrNull();

    xdgSurface = xdgWmBase?.getXdgSurface(surface!).getOrNull();
    xdgSurface?.onConfigure(onXdgSurfaceConfigure);

    xdgTopLevel = xdgSurface?.getToplevel().getOrNull();

    xdgTopLevel?.onConfigure(onXdgTopLevelConfigure);

    xdgTopLevel?.onClose(onXdgTopLevelClose);

    xdgTopLevel?.setTitle("Dart wayland");
    xdgTopLevel?.setAppId("dart-wayland");
    surface?.commit();

    _createDispatchIsolate();
  }

  roundTrip() {
    var callback = display?.sync().getOrElse((a) {
      logLn("sync failed: $a");
      exit(-1);
    });

    bool done = false;
    callback?.onDone((val) {
      logLn("callback.ondone: $val\n");
      done = true;
    });
    while (!done) {
      dispatch();
    }
  }

  dispatch() {
    context.dispatch();
  }

  onDisplayError(DisplayErrorEvent a) {
    logLn("display.onerror: $a");
  }

  onDisplayDeleteId(DisplayDeleteIdEvent a) {
    logLn("display.ondeleteId: $a");
  }

  onXdgWmBasePing(ping) {
    logLn("xdg_wm_base ping: $ping");
    xdgWmBase?.pong(ping.serial);
    logLn("xdg_wm_base pong sent");
  }

  onXdgSurfaceConfigure(con) {
    logLn("surface onConfigure $xdgSurface");
    xdgSurface?.ackConfigure(con.serial);

    final stride = width * 4;
    _bufferSize = stride * height;

    _bufferFd = createAnonymousFile(_bufferSize);

    ShmPool? pool = shm!.createPool(_bufferFd, _bufferSize).getOrNull();

    buffer = pool
        ?.createBuffer(
          0,
          width,
          height,
          stride,
          ShmFormat.argb8888.enumValue,
        )
        .getOrNull();

    buffer?.onRelease(onBufferRelease);

    final canvas = Canvas(width, height, PixelFormat.argb8888);

    paint(canvas);
    writeToFd(_bufferFd, canvas.pixels);

    surface?.attach(buffer!, 0, 0).getOrNull();

    surface?.commit().getOrThrow();
  }

  paint(Canvas canvas) {}

  onBufferRelease(BufferReleaseEvent releaseEvent) {
    logLn("buffer onRelease: $releaseEvent");
    buffer?.destroy();
  }

  onXdgTopLevelConfigure(XdgToplevelConfigureEvent a) {
    logLn("xdgTopLevel onConfigure $a");
    if (a.width != 0 && a.height != 0) {
      setDimensions(a.width, a.height);
    } else {
      return;
    }
  }

  onXdgTopLevelClose(XdgToplevelCloseEvent a) {
    logLn("xdgTopLevel onClose $xdgTopLevel");
  }

  onSeatCapabilities(SeatCapabilitiesEvent capa) {
    logLn("seat capabilities: $capa");

    bool havePointer =
        (capa.capabilities & SeatCapability.pointer.enumValue) != 0;
    bool haveKeyboard =
        (capa.capabilities & SeatCapability.keyboard.enumValue) != 0;

    if (havePointer && pointer == null) {
      attachPointer();
    } else if (!havePointer && pointer != null) {
      releasePointer();
    }

    if (haveKeyboard && keyboard == null) {
      attachKeyboard();
    } else if (!haveKeyboard && keyboard != null) {
      releaseKeyboard();
    }
  }

  attachKeyboard() {
    keyboard = seat?.getKeyboard().getOrNull();

    keyboard?.onKey((KeyboardKeyEvent a) {
      logLn("keyboard onKey: $a");

      final keyEvent = KeyEvent(
        a.key,
        a.state == KeyboardKeyState.pressed.enumValue,
        _modifierState,
      );
      if (a.state == KeyboardKeyState.pressed.enumValue) {
        pushEvent(keyEvent);
      } else if (a.state == KeyboardKeyState.released.enumValue) {
        pushEvent(keyEvent);
      }
    });

    keyboard?.onModifiers((KeyboardModifiersEvent a) {
      logLn("keyboard onModifiers: $a");

      _modifierState = ModifierState(
        modsDepressed: a.modsDepressed,
        modsLatched: a.modsLatched,
        modsLocked: a.modsLatched,
        group: a.group,
      );
      print(ModifierState(
        modsDepressed: a.modsDepressed,
        modsLatched: a.modsLatched,
        modsLocked: a.modsLatched,
        group: a.group,
      ));
    });

    keyboard?.onEnter((KeyboardEnterEvent a) {
      logLn("keyboard onEnter: $a");
    });

    keyboard?.onLeave((KeyboardLeaveEvent a) {
      logLn("keyboard onLeave: $a");
    });

    keyboard?.onKeymap((KeyboardKeymapEvent a) {
      logLn("keyboard onKeymap: $a");
    });

    keyboard?.onRepeatInfo((KeyboardRepeatInfoEvent a) {
      print("keyboard onRepeatInfo: $a");
    });
  }

  releaseKeyboard() {
    keyboard?.release().fold((success) {
      keyboard = null;
    }, (fail) {
      logLn("keyboard release failed: $fail");
    });
  }

  onSeatName(SeatNameEvent name) {
    logLn("seat name: $name");
  }

  onGlobalRemove(RegistryGlobalRemoveEvent a) {
    logLn("global remove: $a");
  }

  registryGlobalHandler(RegistryGlobalEvent global) async {
    try {
      switch (global.interface) {
        case "wl_compositor":
          compositor = Compositor(context);
          registry?.bind(global.name, global.interface, global.version,
              compositor!.objectId);
          break;
        case "wl_subcompositor":
          subCompositor = Subcompositor(context);
          registry?.bind(global.name, global.interface, global.version,
              subCompositor!.objectId);
          break;
        case "wl_shm":
          shm = Shm(context);
          shm?.onFormat(((format) {
            logLn("shm format: $format");
          }));
          registry?.bind(
              global.name, global.interface, global.version, shm!.objectId);
          break;
        case "wl_seat":
          seat = Seat(context);
          seat?.onCapabilities(onSeatCapabilities);
          seat?.onName((name) {
            logLn("seat name: $name");
          });
          registry?.bind(
              global.name, global.interface, global.version, seat!.objectId);
          break;
        case "xdg_wm_base":
          xdgWmBase = XdgWmBase(context);
          xdgWmBase?.onPing(onXdgWmBasePing);
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

  void attachPointer() {
    pointer = seat?.getPointer().getOrNull();
    pointer?.onEnter((PointerEnterEvent a) {
      logLn("pointer onEnter: $a");
    });

    pointer?.onLeave((PointerLeaveEvent a) {
      logLn("pointer onLeave: $a");
    });

    pointer?.onMotion((PointerMotionEvent a) {
      logLn("pointer onMotion: $a");
      final event = MouseMotionEvent(a.surfaceX, a.surfaceY);
      mouseX = a.surfaceX;
      mouseY = a.surfaceY;
      pushEvent(event);
    });

    pointer?.onButton((PointerButtonEvent a) {
      logLn("pointer onButton: $a");
      final buttonEvent = MouseButtonEvent(mouseX, mouseY, a.button,
          a.state == PointerButtonState.pressed.enumValue);

      if (a.state == PointerButtonState.pressed.enumValue) {
        pushEvent(buttonEvent);
      } else if (a.state == PointerButtonState.released.enumValue) {
        pushEvent(buttonEvent);
      }
    });

    pointer?.onAxis((PointerAxisEvent a) {
      logLn("pointer onAxis: $a");
    });

    pointer?.onFrame((PointerFrameEvent a) {
      logLn("pointer onFrame: $a");
    });

    pointer?.onAxisSource((PointerAxisSourceEvent a) {
      logLn("pointer onAxisSource: $a");
    });

    pointer?.onAxisStop((PointerAxisStopEvent a) {
      logLn("pointer onAxisStop: $a");
    });
    pointer?.onAxisDiscrete((PointerAxisDiscreteEvent a) {
      logLn("pointer onAxisDiscrete: $a");
    });
  }

  void releasePointer() {
    pointer?.release().fold((success) {
      pointer = null;
    }, (fail) {});
  }
}
