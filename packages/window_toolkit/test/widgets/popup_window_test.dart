import 'package:test/test.dart';
import 'package:window_toolkit/window_toolkit.dart';

void main() {
  group('PopupWindow', () {
    test('requires Wayland connection — skip without compositor', () {
      // PopupWindow requires a live Wayland compositor connection
      // (PopupBackend connects to the Wayland display server).
      // Integration test: launch under a compositor and verify popups.
    });
  });
}
