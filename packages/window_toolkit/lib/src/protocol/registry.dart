import 'dart:io';

import 'package:wayland/wayland.dart';

/// A protocol global that the toolkit knows how to bind.
///
/// Protocols are deliberately described as optional capabilities.  A toolkit
/// application can therefore use the same code on wlroots, Hyprland, Mutter,
/// KWin, or a minimal compositor without having to bind every protocol up
/// front.
class WaylandProtocolDescriptor {
  const WaylandProtocolDescriptor(
    this.interfaceName,
    this.maxVersion,
    this.create,
  );

  final String interfaceName;
  final int maxVersion;
  final dynamic Function(Context context) create;
}

/// The optional protocol globals discovered on a connection.
///
/// This registry owns only the client-side proxy objects.  Their lifetime is
/// tied to the [Context], just like the mandatory objects already exposed by
/// [WaylandConnection].
class WaylandProtocolRegistry {
  WaylandProtocolRegistry(this.context, this.registry);

  final Context context;
  final WlRegistry registry;
  final Map<String, dynamic> _objects = <String, dynamic>{};
  final Map<String, int> _versions = <String, int>{};
  final Map<String, int> _globalNames = <String, int>{};
  final List<void Function(String interfaceName, dynamic object)> _listeners =
      <void Function(String interfaceName, dynamic object)>[];
  final List<void Function(String interfaceName)> _removeListeners =
      <void Function(String interfaceName)>[];

  /// Bindable globals used by toolkit services.
  ///
  /// The list intentionally includes both stable and compositor-specific
  /// protocols.  Binding is harmless when a compositor does not advertise a
  /// global, and services can check [contains] before using one.
  static final List<WaylandProtocolDescriptor>
  descriptors = <WaylandProtocolDescriptor>[
    // Output, presentation and surface composition.
    WaylandProtocolDescriptor('wp_presentation', 1, WpPresentation.new),
    WaylandProtocolDescriptor('wp_viewporter', 1, WpViewporter.new),
    WaylandProtocolDescriptor(
      'wp_fractional_scale_manager_v1',
      1,
      WpFractionalScaleManagerV1.new,
    ),
    WaylandProtocolDescriptor(
      'zxdg_output_manager_v1',
      3,
      ZxdgOutputManagerV1.new,
    ),
    WaylandProtocolDescriptor('wp_fifo_manager_v1', 1, WpFifoManagerV1.new),
    WaylandProtocolDescriptor(
      'wp_commit_timing_manager_v1',
      1,
      WpCommitTimingManagerV1.new,
    ),
    WaylandProtocolDescriptor(
      'wp_tearing_control_manager_v1',
      1,
      WpTearingControlManagerV1.new,
    ),
    WaylandProtocolDescriptor(
      'wp_content_type_manager_v1',
      1,
      WpContentTypeManagerV1.new,
    ),
    WaylandProtocolDescriptor(
      'wp_single_pixel_buffer_manager_v1',
      1,
      WpSinglePixelBufferManagerV1.new,
    ),
    WaylandProtocolDescriptor('wp_alpha_modifier_v1', 1, WpAlphaModifierV1.new),
    WaylandProtocolDescriptor('wp_color_manager_v1', 1, WpColorManagerV1.new),
    WaylandProtocolDescriptor(
      'wp_color_representation_manager_v1',
      1,
      WpColorRepresentationManagerV1.new,
    ),
    WaylandProtocolDescriptor(
      'wp_linux_drm_syncobj_manager_v1',
      1,
      WpLinuxDrmSyncobjManagerV1.new,
    ),
    WaylandProtocolDescriptor('zwp_linux_dmabuf_v1', 4, ZwpLinuxDmabufV1.new),
    WaylandProtocolDescriptor(
      'zwp_linux_explicit_synchronization_v1',
      1,
      ZwpLinuxExplicitSynchronizationV1.new,
    ),

    // Workspaces, windows and activation.
    WaylandProtocolDescriptor(
      'ext_workspace_manager_v1',
      1,
      ExtWorkspaceManagerV1.new,
    ),
    WaylandProtocolDescriptor(
      'zwlr_foreign_toplevel_manager_v1',
      3,
      ForeignToplevelManagerV1.new,
    ),
    WaylandProtocolDescriptor(
      'ext_foreign_toplevel_list_v1',
      1,
      ExtForeignToplevelListV1.new,
    ),
    WaylandProtocolDescriptor('xdg_activation_v1', 1, XdgActivationV1.new),
    WaylandProtocolDescriptor(
      'zxdg_decoration_manager_v1',
      1,
      ZxdgDecorationManagerV1.new,
    ),
    WaylandProtocolDescriptor(
      'xdg_session_manager_v1',
      1,
      XdgSessionManagerV1.new,
    ),

    // Clipboard and selection.
    WaylandProtocolDescriptor(
      'wl_data_device_manager',
      3,
      WlDataDeviceManager.new,
    ),
    WaylandProtocolDescriptor(
      'zwp_primary_selection_device_manager_v1',
      1,
      ZwpPrimarySelectionDeviceManagerV1.new,
    ),
    WaylandProtocolDescriptor(
      'ext_data_control_manager_v1',
      1,
      ExtDataControlManagerV1.new,
    ),
    WaylandProtocolDescriptor(
      'zwlr_data_control_manager_v1',
      2,
      DataControlManagerV1.new,
    ),

    // Pointer, tablet and keyboard input.
    WaylandProtocolDescriptor(
      'zwp_relative_pointer_manager_v1',
      1,
      ZwpRelativePointerManagerV1.new,
    ),
    WaylandProtocolDescriptor(
      'zwp_pointer_constraints_v1',
      1,
      ZwpPointerConstraintsV1.new,
    ),
    WaylandProtocolDescriptor(
      'zwp_pointer_gestures_v1',
      3,
      ZwpPointerGesturesV1.new,
    ),
    WaylandProtocolDescriptor(
      'zwp_input_timestamps_manager_v1',
      1,
      ZwpInputTimestampsManagerV1.new,
    ),
    WaylandProtocolDescriptor(
      'zwp_keyboard_shortcuts_inhibit_manager_v1',
      1,
      ZwpKeyboardShortcutsInhibitManagerV1.new,
    ),
    WaylandProtocolDescriptor(
      'wp_cursor_shape_manager_v1',
      1,
      WpCursorShapeManagerV1.new,
    ),
    WaylandProtocolDescriptor(
      'zwp_virtual_pointer_manager_v1',
      2,
      VirtualPointerManagerV1.new,
    ),
    WaylandProtocolDescriptor(
      'zwp_tablet_manager_v2',
      1,
      ZwpTabletManagerV2.new,
    ),
    WaylandProtocolDescriptor(
      'zwp_tablet_manager_v1',
      1,
      ZwpTabletManagerV1.new,
    ),
    WaylandProtocolDescriptor(
      'zwp_text_input_manager_v3',
      1,
      ZwpTextInputManagerV3.new,
    ),
    WaylandProtocolDescriptor(
      'zwp_text_input_manager_v1',
      1,
      ZwpTextInputManagerV1.new,
    ),
    WaylandProtocolDescriptor('zwp_input_method_v1', 1, ZwpInputMethodV1.new),
    WaylandProtocolDescriptor(
      'zwp_xwayland_keyboard_grab_manager_v1',
      1,
      ZwpXwaylandKeyboardGrabManagerV1.new,
    ),

    // Idle and power policy.
    WaylandProtocolDescriptor(
      'zwp_idle_inhibit_manager_v1',
      1,
      ZwpIdleInhibitManagerV1.new,
    ),
    WaylandProtocolDescriptor('ext_idle_notifier_v1', 1, ExtIdleNotifierV1.new),
    WaylandProtocolDescriptor(
      'zwlr_output_power_manager_v1',
      1,
      OutputPowerManagerV1.new,
    ),
    WaylandProtocolDescriptor(
      'zwlr_gamma_control_manager_v1',
      1,
      GammaControlManagerV1.new,
    ),
    WaylandProtocolDescriptor(
      'zwlr_input_inhibit_manager_v1',
      1,
      InputInhibitManagerV1.new,
    ),

    // Capture and export.
    WaylandProtocolDescriptor(
      'ext_output_image_capture_source_manager_v1',
      1,
      ExtOutputImageCaptureSourceManagerV1.new,
    ),
    WaylandProtocolDescriptor(
      'ext_foreign_toplevel_image_capture_source_manager_v1',
      1,
      ExtForeignToplevelImageCaptureSourceManagerV1.new,
    ),
    WaylandProtocolDescriptor(
      'ext_image_copy_capture_manager_v1',
      1,
      ExtImageCopyCaptureManagerV1.new,
    ),
    WaylandProtocolDescriptor(
      'zwlr_screencopy_manager_v1',
      3,
      ScreencopyManagerV1.new,
    ),
    WaylandProtocolDescriptor(
      'zwlr_export_dmabuf_manager_v1',
      1,
      ExportDmabufManagerV1.new,
    ),

    // Security, session and specialized compositor features.
    WaylandProtocolDescriptor(
      'ext_session_lock_manager_v1',
      1,
      ExtSessionLockManagerV1.new,
    ),
    WaylandProtocolDescriptor(
      'wp_security_context_manager_v1',
      1,
      WpSecurityContextManagerV1.new,
    ),
    WaylandProtocolDescriptor(
      'ext_transient_seat_manager_v1',
      1,
      ExtTransientSeatManagerV1.new,
    ),
    WaylandProtocolDescriptor(
      'wp_drm_lease_device_v1',
      1,
      WpDrmLeaseDeviceV1.new,
    ),
    WaylandProtocolDescriptor('zwlr_output_manager_v1', 4, OutputManagerV1.new),
    WaylandProtocolDescriptor(
      'zwp_fullscreen_shell_v1',
      1,
      ZwpFullscreenShellV1.new,
    ),
    WaylandProtocolDescriptor(
      'ext_background_effect_manager_v1',
      1,
      ExtBackgroundEffectManagerV1.new,
    ),
  ];

  Iterable<String> get interfaces => _objects.keys;

  bool contains(String interfaceName) => _objects.containsKey(interfaceName);

  dynamic operator [](String interfaceName) => _objects[interfaceName];

  T? get<T>(String interfaceName) {
    final object = _objects[interfaceName];
    return object is T ? object : null;
  }

  int? versionOf(String interfaceName) => _versions[interfaceName];

  void addListener(
    void Function(String interfaceName, dynamic object) listener,
  ) {
    _listeners.add(listener);
    for (final entry in _objects.entries) {
      listener(entry.key, entry.value);
    }
  }

  void addRemoveListener(void Function(String interfaceName) listener) {
    _removeListeners.add(listener);
  }

  /// Bind a global if it is in the catalog and has not already been bound.
  dynamic bind(dynamic global) {
    if (_objects.containsKey(global.interface))
      return _objects[global.interface];

    WaylandProtocolDescriptor? descriptor;
    for (final candidate in descriptors) {
      if (candidate.interfaceName == global.interface) {
        descriptor = candidate;
        break;
      }
    }
    if (descriptor == null) return null;

    final version = global.version is int
        ? (global.version as int).clamp(1, descriptor.maxVersion)
        : descriptor.maxVersion;
    final object = descriptor.create(context);
    registry.bind(global.name, global.interface, version, object.objectId);
    _objects[global.interface] = object;
    _versions[global.interface] = version;
    _globalNames[global.interface as String] = global.name as int;
    for (final listener in _listeners) {
      listener(global.interface as String, object);
    }
    return object;
  }

  /// Remove a capability whose advertised global disappeared.
  void removeGlobal(int globalName) {
    String? interfaceName;
    for (final entry in _globalNames.entries) {
      if (entry.value == globalName) {
        interfaceName = entry.key;
        break;
      }
    }
    if (interfaceName == null) return;
    _globalNames.remove(interfaceName);
    _objects.remove(interfaceName);
    _versions.remove(interfaceName);
    for (final listener in _removeListeners) {
      listener(interfaceName);
    }
  }

  void reset() {
    _objects.clear();
    _versions.clear();
    _globalNames.clear();
  }

  /// Log the advertised optional globals. Useful when diagnosing compositor
  /// differences without forcing every client to know protocol internals.
  void logSummary() {
    if (_objects.isEmpty) {
      stderr.writeln('[wt:protocol] no optional globals bound');
      return;
    }
    stderr.writeln(
      '[wt:protocol] bound ${_objects.length} optional globals: '
      '${_objects.keys.join(', ')}',
    );
  }
}
