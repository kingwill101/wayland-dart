/// Wayland protocol bindings for Dart
library wayland;

export 'src/protocol/protocol.dart';
export 'src/protocol/shared_memory.dart' show createAnonymousFile, writeToFd, closeFd, mmapFd, munmap;

// Core wayland protocol
export 'protocols/wayland.dart';

// Stable protocols
export 'protocols/stable/linux-dmabuf/linux_dmabuf_v1.dart';
export 'protocols/stable/presentation-time/presentation_time.dart';
export 'protocols/stable/tablet/tablet_v2.dart';
export 'protocols/stable/viewporter/viewporter.dart';
export 'protocols/stable/xdg-shell/xdg_shell.dart';

// Staging protocols
export 'protocols/staging/alpha-modifier/alpha_modifier_v1.dart';
export 'protocols/staging/color-management/color_management_v1.dart';
export 'protocols/staging/color-representation/color_representation_v1.dart';
export 'protocols/staging/commit-timing/commit_timing_v1.dart';
export 'protocols/staging/content-type/content_type_v1.dart';
export 'protocols/staging/cursor-shape/cursor_shape_v1.dart';
export 'protocols/staging/drm-lease/drm_lease_v1.dart';
export 'protocols/staging/ext-background-effect/ext_background_effect_v1.dart';
export 'protocols/staging/ext-data-control/ext_data_control_v1.dart';
export 'protocols/staging/ext-foreign-toplevel-list/ext_foreign_toplevel_list_v1.dart';
export 'protocols/staging/ext-idle-notify/ext_idle_notify_v1.dart';
export 'protocols/staging/ext-image-capture-source/ext_image_capture_source_v1.dart';
export 'protocols/staging/ext-image-copy-capture/ext_image_copy_capture_v1.dart';
export 'protocols/staging/ext-session-lock/ext_session_lock_v1.dart';
export 'protocols/staging/ext-transient-seat/ext_transient_seat_v1.dart';
export 'protocols/staging/ext-workspace/ext_workspace_v1.dart';
export 'protocols/staging/fifo/fifo_v1.dart';
export 'protocols/staging/fractional-scale/fractional_scale_v1.dart';
export 'protocols/staging/linux-drm-syncobj/linux_drm_syncobj_v1.dart';
export 'protocols/staging/pointer-warp/pointer_warp_v1.dart';
export 'protocols/staging/security-context/security_context_v1.dart';
export 'protocols/staging/single-pixel-buffer/single_pixel_buffer_v1.dart';
export 'protocols/staging/tearing-control/tearing_control_v1.dart';
export 'protocols/staging/xdg-activation/xdg_activation_v1.dart';
export 'protocols/staging/xdg-dialog/xdg_dialog_v1.dart';
export 'protocols/staging/xdg-system-bell/xdg_system_bell_v1.dart';
export 'protocols/staging/xdg-toplevel-drag/xdg_toplevel_drag_v1.dart';
export 'protocols/staging/xdg-toplevel-icon/xdg_toplevel_icon_v1.dart';
export 'protocols/staging/xdg-toplevel-tag/xdg_toplevel_tag_v1.dart';
export 'protocols/staging/xwayland-shell/xwayland_shell_v1.dart';

// Unstable protocols (excluding duplicates with stable)
export 'protocols/unstable/fullscreen-shell/fullscreen_shell_unstable_v1.dart';
export 'protocols/unstable/idle-inhibit/idle_inhibit_unstable_v1.dart';
export 'protocols/unstable/input-method/input_method_unstable_v1.dart';
export 'protocols/unstable/input-timestamps/input_timestamps_unstable_v1.dart';
export 'protocols/unstable/keyboard-shortcuts-inhibit/keyboard_shortcuts_inhibit_unstable_v1.dart';
export 'protocols/unstable/linux-explicit-synchronization/linux_explicit_synchronization_unstable_v1.dart';
export 'protocols/unstable/pointer-constraints/pointer_constraints_unstable_v1.dart';
export 'protocols/unstable/pointer-gestures/pointer_gestures_unstable_v1.dart';
export 'protocols/unstable/primary-selection/primary_selection_unstable_v1.dart';
export 'protocols/unstable/relative-pointer/relative_pointer_unstable_v1.dart';
export 'protocols/unstable/tablet/tablet_unstable_v1.dart';
export 'protocols/unstable/text-input/text_input_unstable_v1.dart';
export 'protocols/unstable/text-input/text_input_unstable_v3.dart';
export 'protocols/unstable/xdg-decoration/xdg_decoration_unstable_v1.dart';
export 'protocols/unstable/xdg-foreign/xdg_foreign_unstable_v1.dart';
export 'protocols/unstable/xdg-foreign/xdg_foreign_unstable_v2.dart';
export 'protocols/unstable/xdg-output/xdg_output_unstable_v1.dart';
export 'protocols/unstable/xwayland-keyboard-grab/xwayland_keyboard_grab_unstable_v1.dart';

// wlr-protocols (https://gitlab.freedesktop.org/wlroots/wlr-protocols)
export 'protocols/wlr/wlr_layer_shell_unstable_v1.dart';
export 'protocols/wlr/wlr_foreign_toplevel_management_unstable_v1.dart';
export 'protocols/wlr/wlr_output_management_unstable_v1.dart';
export 'protocols/wlr/wlr_output_power_management_unstable_v1.dart';
export 'protocols/wlr/wlr_data_control_unstable_v1.dart';
export 'protocols/wlr/wlr_gamma_control_unstable_v1.dart';
export 'protocols/wlr/wlr_input_inhibitor_unstable_v1.dart';
export 'protocols/wlr/wlr_export_dmabuf_unstable_v1.dart';
export 'protocols/wlr/wlr_screencopy_unstable_v1.dart';
export 'protocols/wlr/wlr_virtual_pointer_unstable_v1.dart';
