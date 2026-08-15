import 'dart:io';

import 'package:wayland/wayland.dart';

import '../app.dart';
import '../keymap.dart';
import '../mixins/event.dart';
import '../modifier_keys.dart';
import '../protocol/registry.dart';
import '../protocol/services.dart';

class WaylandConnection {
  final List<void Function(dynamic global)> _globalHandlers = [];
  final List<dynamic> _globals = [];
  bool _connected = false;

  late Context context;
  late WlDisplay display;
  late WlRegistry registry;
  late WlCompositor compositor;
  late WlShm shm;
  late WlSeat seat;
  late XdgWmBase xdgWmBase;
  late WlOutput output;
  final List<WlOutput> outputs = <WlOutput>[];

  WlPointer? _pointer;
  double _pointerX = 0;
  double _pointerY = 0;

  /// Wayland object id of the surface currently under the pointer, or null.
  int? pointerSurfaceId;

  WlSubcompositor? subcompositor;

  /// Shared layer-shell global (bound once). Used by [LayerBackend] and
  /// popups such as tray menus that need a second layer surface.
  LayerShellV1? layerShell;

  /// Optional protocol capabilities advertised by the compositor.
  ///
  /// The registry is intentionally separate from the mandatory core objects
  /// above.  Toolkit services can depend on a capability without making a
  /// compositor implement every staging or wlroots protocol.
  WaylandProtocolRegistry? protocols;
  WaylandServices? services;

  /// libxkbcommon keyboard state for character decoding.
  final XkbKeyboard keyboard = XkbKeyboard();
  double _axisDx = 0;
  double _axisDy = 0;
  bool _accumulatingAxis = false;

  WlKeyboard? _keyboard;

  bool get isConnected => _connected && context.isConnected;

  void reset() {
    _globalHandlers.clear();
    _globals.clear();
    _connected = false;
    layerShell = null;
    subcompositor = null;
    pointerSurfaceId = null;
    outputs.clear();
    protocols?.reset();
    services = null;
  }

  /// Release native resources: xkb keymap/state and Wayland socket.
  void dispose() {
    keyboard.dispose();
    context.close();
  }

  void addGlobalHandler(void Function(dynamic global) handler) {
    _globalHandlers.add(handler);
    for (final global in _globals) {
      handler(global);
    }
  }

  Future<void> connect() async {
    if (_connected) return;

    context = Context();
    await context.connect();

    display = WlDisplay(context);
    display.onError((e) {
      stderr.writeln('[wt] display error: $e');
      _connected = false;
    });

    registry = display.getRegistry().getOrElse((e) {
      stderr.writeln('[wt] getRegistry failed: $e');
      return WlRegistry(context);
    });

    protocols = WaylandProtocolRegistry(context, registry);

    registry.onGlobal(_onGlobal);
    registry.onGlobalRemove((g) {
      protocols?.removeGlobal(g.name);
    });

    _roundtrip();
    _roundtrip();

    services = WaylandServices(context, protocols!, outputs: outputs);
    protocols!.logSummary();

    _connected = true;
  }

  void _onGlobal(dynamic global) {
    _globals.add(global);

    switch (global.interface) {
      case 'wl_compositor':
        compositor = WlCompositor(context);
        registry.bind(
          global.name,
          global.interface,
          global.version,
          compositor.objectId,
        );
      case 'wl_shm':
        shm = WlShm(context);
        registry.bind(
          global.name,
          global.interface,
          global.version,
          shm.objectId,
        );
      case 'wl_seat':
        seat = WlSeat(context);
        registry.bind(
          global.name,
          global.interface,
          global.version,
          seat.objectId,
        );
        seat.onCapabilities((e) {
          if (e.capabilities & WlSeatCapability.pointer.enumValue != 0) {
            _setupPointer();
          }
          if (e.capabilities & WlSeatCapability.keyboard.enumValue != 0) {
            _setupKeyboard();
          }
        });
      case 'xdg_wm_base':
        xdgWmBase = XdgWmBase(context);
        xdgWmBase.onPing((p) => xdgWmBase.pong(p.serial));
        registry.bind(
          global.name,
          global.interface,
          global.version,
          xdgWmBase.objectId,
        );
      case 'wl_subcompositor':
        subcompositor = WlSubcompositor(context);
        registry.bind(
          global.name,
          global.interface,
          global.version,
          subcompositor!.objectId,
        );
      case 'zwlr_layer_shell_v1':
        if (layerShell == null) {
          layerShell = LayerShellV1(context);
          registry.bind(
            global.name,
            global.interface,
            global.version,
            layerShell!.objectId,
          );
        }
      case 'wl_output':
        final boundOutput = WlOutput(context);
        output = boundOutput;
        outputs.add(boundOutput);
        registry.bind(
          global.name,
          global.interface,
          global.version,
          boundOutput.objectId,
        );
    }

    // Bind optional protocol globals after the mandatory toolkit globals have
    // been handled.  This keeps the existing connection fields stable while
    // making every supported protocol discoverable through one registry.
    protocols?.bind(global);

    for (final handler in _globalHandlers) {
      handler(global);
    }
  }

  void _setupPointer() {
    _pointer = seat.getPointer().getOrElse((e) {
      stderr.writeln('[wt] getPointer failed: $e');
      return WlPointer(context);
    });
    _pointer!.onEnter((e) {
      pointerSurfaceId = e.surface;
      _pointerX = e.surfaceX;
      _pointerY = e.surfaceY;
      Application.instance.dispatchEvent(MouseEnterEvent(_pointerX, _pointerY));
    });
    _pointer!.onLeave((e) {
      if (pointerSurfaceId == e.surface) pointerSurfaceId = null;
      Application.instance.dispatchEvent(MouseLeaveEvent(_pointerX, _pointerY));
    });
    _pointer!.onMotion((e) {
      _pointerX = e.surfaceX;
      _pointerY = e.surfaceY;
      Application.instance.dispatchEvent(
        MouseMotionEvent(_pointerX, _pointerY),
      );
    });
    _pointer!.onButton((e) {
      Application.instance.dispatchEvent(
        MouseButtonEvent(_pointerX, _pointerY, e.button, e.state == 1),
      );
    });
    _pointer!.onAxis((e) {
      _accumulatingAxis = true;
      // Wayland axis enum: vertical_scroll=0, horizontal_scroll=1
      if (e.axis == 0) {
        _axisDy += e.value;
      } else {
        _axisDx += e.value;
      }
    });
    _pointer!.onFrame((_) {
      if (_accumulatingAxis) {
        Application.instance.dispatchEvent(
          MouseWheelEvent(_pointerX, _pointerY, _axisDx, _axisDy),
        );
        _axisDx = 0;
        _axisDy = 0;
        _accumulatingAxis = false;
      }
    });
  }

  void _setupKeyboard() {
    _keyboard = seat.getKeyboard().getOrElse((e) {
      stderr.writeln('[wt] getKeyboard failed: $e');
      return WlKeyboard(context);
    });

    // Receive the xkb keymap from the compositor
    _keyboard!.onKeymap((e) {
      keyboard.loadKeymap(e.format, e.fd, e.size);
    });

    _keyboard!.onKey((e) {
      final keyState = e.state == 1;
      // Decode character via xkbcommon (keycode + 8 for xkb offset)
      final char = keyboard.keyEvent(e.key, keyState);

      // Modifier tracking needs xkb_state; fall back to flat zeros.
      final mods = ModifierState(
        modsDepressed: 0,
        modsLatched: 0,
        modsLocked: 0,
        group: 0,
      );
      Application.instance.dispatchEvent(
        KeyEvent(e.key, keyState, mods, character: char),
      );
    });

    _keyboard!.onModifiers((e) {
      keyboard.updateModifiers(
        e.modsDepressed,
        e.modsLatched,
        e.modsLocked,
        e.group,
      );
    });
  }

  void _roundtrip() {
    final callback = display.sync().getOrElse((e) {
      stderr.writeln('[wt] sync failed: $e');
      return WlCallback(context);
    });
    var done = false;
    callback.onDone((_) {
      done = true;
    });
    while (!done) {
      context.dispatch();
    }
  }

  void dispatch() {
    context.dispatchTimeout(0);
  }

  /// Dispatch Wayland events, blocking up to [timeoutMs] ms for data.
  /// Use a positive timeout (e.g. 16ms) instead of 0 so the poll()
  /// syscall survives VM service pauses (CPU profiler, heap snapshot).
  void dispatchTimeout(int timeoutMs) {
    context.dispatchTimeout(timeoutMs);
  }
}
