import 'dart:async';

import 'package:wayland/wayland.dart';

import 'registry.dart';

typedef WaylandServiceListener<T> = void Function(T value);

/// Coherent output metadata assembled from wl_output and xdg-output events.
class WaylandOutputInfo {
  WaylandOutputInfo(this.output);

  final WlOutput output;
  String? name;
  String? description;
  int scale = 1;
  int? logicalX;
  int? logicalY;
  int? logicalWidth;
  int? logicalHeight;
  int? modeWidth;
  int? modeHeight;
  int? refreshMilliHz;
}

class WaylandOutputService {
  WaylandOutputService(this.protocols, Iterable<WlOutput> outputs) {
    for (final output in outputs) {
      _attach(output);
    }
  }

  final WaylandProtocolRegistry protocols;
  final Map<int, WaylandOutputInfo> _outputs = <int, WaylandOutputInfo>{};
  final List<void Function()> _listeners = <void Function()>[];

  List<WaylandOutputInfo> get outputs =>
      _outputs.values.toList(growable: false);
  void addListener(void Function() listener) => _listeners.add(listener);

  void _attach(WlOutput output) {
    if (_outputs.containsKey(output.objectId)) return;
    final info = WaylandOutputInfo(output);
    _outputs[output.objectId] = info;
    output.onScale((event) {
      info.scale = event.factor;
      _notify();
    });
    output.onMode((event) {
      if (event.flags & 1 != 0) {
        info.modeWidth = event.width;
        info.modeHeight = event.height;
        info.refreshMilliHz = event.refresh;
      }
      _notify();
    });
    output.onName((event) {
      info.name = event.name;
      _notify();
    });
    output.onDescription((event) {
      info.description = event.description;
      _notify();
    });

    final manager = protocols.get<ZxdgOutputManagerV1>(
      'zxdg_output_manager_v1',
    );
    if (manager != null) {
      try {
        final xdg = manager.getXdgOutput(output).getOrElse((error) {
          throw StateError('xdg output failed: $error');
        });
        xdg.onLogicalPosition((event) {
          info.logicalX = event.x;
          info.logicalY = event.y;
          _notify();
        });
        xdg.onLogicalSize((event) {
          info.logicalWidth = event.width;
          info.logicalHeight = event.height;
          _notify();
        });
        xdg.onName((event) {
          info.name = event.name;
          _notify();
        });
        xdg.onDescription((event) {
          info.description = event.description;
          _notify();
        });
      } catch (_) {
        // xdg-output is optional and may disappear during hotplug races.
      }
    }
  }

  void _notify() {
    for (final listener in List<void Function()>.of(_listeners)) {
      listener();
    }
  }
}

/// A compositor workspace exposed through `ext-workspace-v1`.
class WaylandWorkspace {
  WaylandWorkspace(this.handle);

  final ExtWorkspaceHandleV1 handle;
  String? id;
  String? name;
  List<int> coordinates = const <int>[];
  int state = 0;
  int capabilities = 0;

  bool get active => state & ExtWorkspaceHandleV1State.active.enumValue != 0;
  bool get urgent => state & ExtWorkspaceHandleV1State.urgent.enumValue != 0;
  bool get hidden => state & ExtWorkspaceHandleV1State.hidden.enumValue != 0;
  bool get canActivate =>
      capabilities &
          ExtWorkspaceHandleV1WorkspaceCapabilities.activate.enumValue !=
      0;
  bool get canDeactivate =>
      capabilities &
          ExtWorkspaceHandleV1WorkspaceCapabilities.deactivate.enumValue !=
      0;

  void activate() => handle.activate();
  void deactivate() => handle.deactivate();
  void destroy() => handle.destroy();
}

/// Typed workspace state and actions for taskbars, docks, and workspace bars.
class WaylandWorkspaceService {
  WaylandWorkspaceService(this.context, this.protocols);

  final Context context;
  final WaylandProtocolRegistry protocols;
  final Map<int, WaylandWorkspace> _workspaces = <int, WaylandWorkspace>{};
  final List<void Function()> _listeners = <void Function()>[];
  ExtWorkspaceManagerV1? _manager;
  bool _listening = false;

  List<WaylandWorkspace> get workspaces {
    _ensureAttached();
    return _workspaces.values.toList(growable: false);
  }

  bool get available {
    _ensureAttached();
    return _manager != null;
  }

  void addListener(void Function() listener) {
    _listeners.add(listener);
    _ensureAttached();
  }

  void _ensureAttached() {
    if (_listening) return;
    _listening = true;
    _attach(protocols.get<ExtWorkspaceManagerV1>('ext_workspace_manager_v1'));
    protocols.addListener((name, object) {
      if (name == 'ext_workspace_manager_v1') {
        _attach(object as ExtWorkspaceManagerV1);
      }
    });
  }

  void _attach(ExtWorkspaceManagerV1? manager) {
    if (manager == null || identical(manager, _manager)) return;
    _manager = manager;
    manager.onWorkspace((event) {
      final handle = ExtWorkspaceHandleV1(context);
      context.adoptProxy(handle, event.workspace);
      final workspace = WaylandWorkspace(handle);
      _workspaces[handle.objectId] = workspace;

      handle.onId((event) {
        workspace.id = event.id;
        _notify();
      });
      handle.onName((event) {
        workspace.name = event.name;
        _notify();
      });
      handle.onCoordinates((event) {
        workspace.coordinates = List<int>.unmodifiable(event.coordinates);
        _notify();
      });
      handle.onState((event) {
        workspace.state = event.state;
        _notify();
      });
      handle.onCapabilities((event) {
        workspace.capabilities = event.capabilities;
        _notify();
      });
      handle.onRemoved((_) {
        _workspaces.remove(handle.objectId);
        handle.destroy();
        _notify();
      });
      _notify();
    });
  }

  void commit() {
    _ensureAttached();
    _manager?.commit();
  }

  void _notify() {
    for (final listener in List<void Function()>.of(_listeners)) {
      listener();
    }
  }
}

/// A toplevel exposed through `zwlr-foreign-toplevel-management-v1`.
class WaylandToplevel {
  WaylandToplevel(this.handle);

  final ForeignToplevelHandleV1 handle;
  String title = '';
  String appId = '';
  List<int> state = const <int>[];
  final Set<int> outputs = <int>{};
  int? parent;

  bool get maximized => state.contains(2);
  bool get minimized => state.contains(3);
  bool get activated => state.contains(4);
  bool get fullscreen => state.contains(1);

  void activate(WlSeat seat) => handle.activate(seat);
  void close() => handle.close();
  void setMaximized() => handle.setMaximized();
  void setMinimized() => handle.setMinimized();
  void setFullscreen(WlOutput output) => handle.setFullscreen(output);
  void unsetFullscreen() => handle.unsetFullscreen();
  void unsetMaximized() => handle.unsetMaximized();
  void unsetMinimized() => handle.unsetMinimized();
}

/// Typed toplevel state used by task switchers and workspace attention UI.
class WaylandForeignToplevelService {
  WaylandForeignToplevelService(this.context, this.protocols);

  final Context context;
  final WaylandProtocolRegistry protocols;
  final Map<int, WaylandToplevel> _toplevels = <int, WaylandToplevel>{};
  final List<void Function()> _listeners = <void Function()>[];
  ForeignToplevelManagerV1? _manager;
  bool _listening = false;

  List<WaylandToplevel> get toplevels {
    _ensureAttached();
    return _toplevels.values.toList(growable: false);
  }

  bool get available {
    _ensureAttached();
    return _manager != null;
  }

  void addListener(void Function() listener) {
    _listeners.add(listener);
    _ensureAttached();
  }

  void _ensureAttached() {
    if (_listening) return;
    _listening = true;
    _attach(
      protocols.get<ForeignToplevelManagerV1>(
        'zwlr_foreign_toplevel_manager_v1',
      ),
    );
    protocols.addListener((name, object) {
      if (name == 'zwlr_foreign_toplevel_manager_v1') {
        _attach(object as ForeignToplevelManagerV1);
      }
    });
  }

  void _attach(ForeignToplevelManagerV1? manager) {
    if (manager == null || identical(manager, _manager)) return;
    _manager = manager;
    manager.onToplevel((event) {
      final handle = ForeignToplevelHandleV1(context);
      context.adoptProxy(handle, event.toplevel);
      final toplevel = WaylandToplevel(handle);
      _toplevels[handle.objectId] = toplevel;

      handle.onTitle((event) {
        toplevel.title = event.title;
        _notify();
      });
      handle.onAppId((event) {
        toplevel.appId = event.appId;
        _notify();
      });
      handle.onState((event) {
        toplevel.state = List<int>.unmodifiable(event.state);
        _notify();
      });
      handle.onOutputEnter((event) {
        toplevel.outputs.add(event.output);
        _notify();
      });
      handle.onOutputLeave((event) {
        toplevel.outputs.remove(event.output);
        _notify();
      });
      handle.onParent((event) {
        toplevel.parent = event.parent == 0 ? null : event.parent;
        _notify();
      });
      handle.onDone((_) => _notify());
      handle.onClosed((_) {
        _toplevels.remove(handle.objectId);
        handle.destroy();
        _notify();
      });
      _notify();
    });
  }

  void _notify() {
    for (final listener in List<void Function()>.of(_listeners)) {
      listener();
    }
  }
}

/// XDG activation token helper. The token is resolved asynchronously by the
/// compositor, while the rest of the toolkit remains event-loop friendly.
class WaylandActivationService {
  WaylandActivationService(this.context, this.protocols);

  final Context context;
  final WaylandProtocolRegistry protocols;

  XdgActivationV1? get manager =>
      protocols.get<XdgActivationV1>('xdg_activation_v1');
  bool get available => manager != null;

  Future<String?> requestToken({
    String? appId,
    WlSurface? surface,
    int? serial,
    WlSeat? seat,
  }) async {
    final activation = manager;
    if (activation == null) return null;

    late final XdgActivationTokenV1 token;
    try {
      token = activation.getActivationToken().getOrElse((error) {
        throw StateError('xdg activation token failed: $error');
      });
    } catch (_) {
      return null;
    }

    final completer = Completer<String?>();
    token.onDone((event) {
      if (!completer.isCompleted) completer.complete(event.token);
      token.destroy();
    });
    if (appId != null) token.setAppId(appId);
    if (surface != null) token.setSurface(surface);
    if (serial != null && seat != null) token.setSerial(serial, seat);
    token.commit();
    return completer.future;
  }

  void activate(String token, WlSurface surface) {
    manager?.activate(token, surface);
  }
}

/// Input extensions that are useful to toolkit surfaces and interactive
/// applications. The returned generated objects remain owned by the caller.
class WaylandInputService {
  WaylandInputService(this.protocols);

  final WaylandProtocolRegistry protocols;

  ZwpRelativePointerManagerV1? get relativePointerManager => protocols
      .get<ZwpRelativePointerManagerV1>('zwp_relative_pointer_manager_v1');
  ZwpPointerConstraintsV1? get pointerConstraints =>
      protocols.get<ZwpPointerConstraintsV1>('zwp_pointer_constraints_v1');
  ZwpPointerGesturesV1? get pointerGestures =>
      protocols.get<ZwpPointerGesturesV1>('zwp_pointer_gestures_v1');
  ZwpKeyboardShortcutsInhibitManagerV1? get keyboardShortcuts =>
      protocols.get<ZwpKeyboardShortcutsInhibitManagerV1>(
        'zwp_keyboard_shortcuts_inhibit_manager_v1',
      );
  WpCursorShapeManagerV1? get cursorShape =>
      protocols.get<WpCursorShapeManagerV1>('wp_cursor_shape_manager_v1');
  ZwpTextInputManagerV3? get textInput =>
      protocols.get<ZwpTextInputManagerV3>('zwp_text_input_manager_v3');

  ZwpRelativePointerV1? createRelativePointer(WlPointer pointer) {
    final manager = relativePointerManager;
    if (manager == null) return null;
    try {
      return manager.getRelativePointer(pointer).getOrElse((error) {
        throw StateError('relative pointer failed: $error');
      });
    } catch (_) {
      return null;
    }
  }

  ZwpKeyboardShortcutsInhibitorV1? inhibitShortcuts(
    WlSurface surface,
    WlSeat seat,
  ) {
    final manager = keyboardShortcuts;
    if (manager == null) return null;
    try {
      return manager.inhibitShortcuts(surface, seat).getOrElse((error) {
        throw StateError('keyboard shortcuts inhibit failed: $error');
      });
    } catch (_) {
      return null;
    }
  }
}

/// Surface lifetime and user-idle policy extensions.
class WaylandIdleService {
  WaylandIdleService(this.protocols);

  final WaylandProtocolRegistry protocols;

  ZwpIdleInhibitManagerV1? get inhibitManager =>
      protocols.get<ZwpIdleInhibitManagerV1>('zwp_idle_inhibit_manager_v1');
  ExtIdleNotifierV1? get notifier =>
      protocols.get<ExtIdleNotifierV1>('ext_idle_notifier_v1');

  ZwpIdleInhibitorV1? inhibit(WlSurface surface) {
    final manager = inhibitManager;
    if (manager == null) return null;
    try {
      return manager.createInhibitor(surface).getOrElse((error) {
        throw StateError('idle inhibit failed: $error');
      });
    } catch (_) {
      return null;
    }
  }

  ExtIdleNotificationV1? watch(int timeoutMs, WlSeat seat) {
    final manager = notifier;
    if (manager == null) return null;
    try {
      return manager.getIdleNotification(timeoutMs, seat).getOrElse((error) {
        throw StateError('idle notification failed: $error');
      });
    } catch (_) {
      return null;
    }
  }
}

/// Clipboard and selection managers. Actual MIME transport is intentionally
/// left to the caller because it is application-specific (text, URI lists,
/// images, and custom binary formats all use different streams).
class WaylandClipboardService {
  WaylandClipboardService(this.protocols);

  final WaylandProtocolRegistry protocols;

  WlDataDeviceManager? get dataDeviceManager =>
      protocols.get<WlDataDeviceManager>('wl_data_device_manager');
  ZwpPrimarySelectionDeviceManagerV1? get primarySelection =>
      protocols.get<ZwpPrimarySelectionDeviceManagerV1>(
        'zwp_primary_selection_device_manager_v1',
      );
  ExtDataControlManagerV1? get dataControl =>
      protocols.get<ExtDataControlManagerV1>('ext_data_control_manager_v1');
  DataControlManagerV1? get wlrDataControl =>
      protocols.get<DataControlManagerV1>('zwlr_data_control_manager_v1');

  WlDataDevice? device(WlSeat seat) {
    final manager = dataDeviceManager;
    if (manager == null) return null;
    try {
      return manager.getDataDevice(seat).getOrElse((error) {
        throw StateError('data device failed: $error');
      });
    } catch (_) {
      return null;
    }
  }
}

/// Capture entry points for both the modern ext-image-copy-capture protocol
/// and the widely deployed wlroots screencopy fallback.
class WaylandCaptureService {
  WaylandCaptureService(this.protocols);

  final WaylandProtocolRegistry protocols;

  ExtOutputImageCaptureSourceManagerV1? get outputSource =>
      protocols.get<ExtOutputImageCaptureSourceManagerV1>(
        'ext_output_image_capture_source_manager_v1',
      );
  ExtForeignToplevelImageCaptureSourceManagerV1? get toplevelSource =>
      protocols.get<ExtForeignToplevelImageCaptureSourceManagerV1>(
        'ext_foreign_toplevel_image_capture_source_manager_v1',
      );
  ExtImageCopyCaptureManagerV1? get imageCopy => protocols
      .get<ExtImageCopyCaptureManagerV1>('ext_image_copy_capture_manager_v1');
  ScreencopyManagerV1? get screencopy =>
      protocols.get<ScreencopyManagerV1>('zwlr_screencopy_manager_v1');
  ExportDmabufManagerV1? get exportDmabuf =>
      protocols.get<ExportDmabufManagerV1>('zwlr_export_dmabuf_manager_v1');

  ExtImageCaptureSourceV1? sourceForOutput(WlOutput output) {
    final manager = outputSource;
    if (manager == null) return null;
    try {
      return manager.createSource(output).getOrElse((error) {
        throw StateError('output capture source failed: $error');
      });
    } catch (_) {
      return null;
    }
  }

  ScreencopyFrameV1? captureOutput(WlOutput output, {bool cursor = true}) {
    final manager = screencopy;
    if (manager == null) return null;
    try {
      return manager.captureOutput(cursor ? 1 : 0, output).getOrElse((error) {
        throw StateError('screencopy failed: $error');
      });
    } catch (_) {
      return null;
    }
  }
}

/// Frame pacing and buffer transport capabilities. These are exposed as
/// typed managers because their requests are surface-specific and belong in
/// the renderer/surface lifecycle rather than in a global singleton helper.
class WaylandFrameService {
  WaylandFrameService(this.protocols);

  final WaylandProtocolRegistry protocols;

  WpPresentation? get presentation =>
      protocols.get<WpPresentation>('wp_presentation');
  WpFifoManagerV1? get fifo =>
      protocols.get<WpFifoManagerV1>('wp_fifo_manager_v1');
  WpCommitTimingManagerV1? get commitTiming =>
      protocols.get<WpCommitTimingManagerV1>('wp_commit_timing_manager_v1');
  WpTearingControlManagerV1? get tearingControl =>
      protocols.get<WpTearingControlManagerV1>('wp_tearing_control_manager_v1');
  ZwpLinuxDmabufV1? get dmabuf =>
      protocols.get<ZwpLinuxDmabufV1>('zwp_linux_dmabuf_v1');
  ZwpLinuxExplicitSynchronizationV1? get explicitSynchronization =>
      protocols.get<ZwpLinuxExplicitSynchronizationV1>(
        'zwp_linux_explicit_synchronization_v1',
      );
}

/// Security, session, output-control, and display-specialization managers.
class WaylandDisplayService {
  WaylandDisplayService(this.protocols);

  final WaylandProtocolRegistry protocols;

  ExtSessionLockManagerV1? get sessionLock =>
      protocols.get<ExtSessionLockManagerV1>('ext_session_lock_manager_v1');
  WpSecurityContextManagerV1? get securityContext => protocols
      .get<WpSecurityContextManagerV1>('wp_security_context_manager_v1');
  OutputManagerV1? get outputManagement =>
      protocols.get<OutputManagerV1>('zwlr_output_manager_v1');
  OutputPowerManagerV1? get outputPower =>
      protocols.get<OutputPowerManagerV1>('zwlr_output_power_manager_v1');
  GammaControlManagerV1? get gammaControl =>
      protocols.get<GammaControlManagerV1>('zwlr_gamma_control_manager_v1');
  WpDrmLeaseDeviceV1? get drmLease =>
      protocols.get<WpDrmLeaseDeviceV1>('wp_drm_lease_device_v1');
  WpColorManagerV1? get colorManagement =>
      protocols.get<WpColorManagerV1>('wp_color_manager_v1');
  WpColorRepresentationManagerV1? get colorRepresentation =>
      protocols.get<WpColorRepresentationManagerV1>(
        'wp_color_representation_manager_v1',
      );
  ExtBackgroundEffectManagerV1? get backgroundEffect => protocols
      .get<ExtBackgroundEffectManagerV1>('ext_background_effect_manager_v1');
}

/// Convenience facade for capability-oriented toolkit code.
class WaylandServices {
  WaylandServices(this.context, this.protocols, {this.seat, outputs})
    : output = WaylandOutputService(protocols, outputs ?? const <WlOutput>[]),
      workspaces = WaylandWorkspaceService(context, protocols),
      foreignToplevels = WaylandForeignToplevelService(context, protocols),
      activation = WaylandActivationService(context, protocols),
      input = WaylandInputService(protocols),
      idle = WaylandIdleService(protocols),
      clipboard = WaylandClipboardService(protocols),
      capture = WaylandCaptureService(protocols),
      frame = WaylandFrameService(protocols),
      display = WaylandDisplayService(protocols);

  final Context context;
  final WaylandProtocolRegistry protocols;
  final WlSeat? seat;
  final WaylandOutputService output;
  final WaylandWorkspaceService workspaces;
  final WaylandForeignToplevelService foreignToplevels;
  final WaylandActivationService activation;
  final WaylandInputService input;
  final WaylandIdleService idle;
  final WaylandClipboardService clipboard;
  final WaylandCaptureService capture;
  final WaylandFrameService frame;
  final WaylandDisplayService display;

  T? optional<T>(String interfaceName) => protocols.get<T>(interfaceName);

  bool supports(String interfaceName) => protocols.contains(interfaceName);
}
