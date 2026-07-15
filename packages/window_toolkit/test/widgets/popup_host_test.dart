import 'package:test/test.dart';
import 'package:window_toolkit/window_toolkit.dart';

void main() {
  group('PopupHost', () {
    test('requires Wayland connection — skip without compositor', () {
      // PopupHost requires a live Wayland compositor connection.
      // Integration test: launch under a compositor and verify popups.
    });
  });
}
