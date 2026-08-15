import 'package:test/test.dart';
import 'package:window_toolkit/window_toolkit.dart';

void main() {
  test('catalogues optional compositor capabilities without duplicates', () {
    final descriptors = WaylandProtocolRegistry.descriptors;
    final interfaces = descriptors.map(
      (descriptor) => descriptor.interfaceName,
    );

    expect(interfaces.toSet(), hasLength(interfaces.length));
    expect(descriptors, isNotEmpty);
    expect(
      descriptors.every((descriptor) => descriptor.maxVersion > 0),
      isTrue,
    );
  });

  test('catalogue covers the toolkit capability groups', () {
    final interfaces = WaylandProtocolRegistry.descriptors
        .map((descriptor) => descriptor.interfaceName)
        .toSet();

    expect(
      interfaces,
      containsAll(<String>[
        'wp_presentation',
        'wp_fractional_scale_manager_v1',
        'ext_workspace_manager_v1',
        'zwlr_foreign_toplevel_manager_v1',
        'xdg_activation_v1',
        'wl_data_device_manager',
        'zwp_primary_selection_device_manager_v1',
        'zwp_relative_pointer_manager_v1',
        'zwp_pointer_constraints_v1',
        'wp_fifo_manager_v1',
        'zwp_linux_explicit_synchronization_v1',
        'zwp_idle_inhibit_manager_v1',
        'ext_idle_notifier_v1',
        'ext_image_copy_capture_manager_v1',
        'zwlr_screencopy_manager_v1',
        'zwp_text_input_manager_v3',
        'ext_session_lock_manager_v1',
      ]),
    );
  });
}
