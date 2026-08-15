import 'package:test/test.dart';
import 'package:window_toolkit/window_toolkit.dart';

void main() {
  group('PopupHost', () {
    test('requires Wayland connection — skip without compositor', () {
      // PopupHost requires a live Wayland compositor connection.
      // Integration test: launch under a compositor and verify popups.
    });

    test('LayerPopupEvent identifies dismissible outside presses', () {
      final press = LayerPopupEvent(
        MouseButtonEvent(12, 18, 0x110, true),
        LayerPopupRegion.outside,
      );
      final release = LayerPopupEvent(
        MouseButtonEvent(12, 18, 0x110, false),
        LayerPopupRegion.outside,
      );
      final contentPress = LayerPopupEvent(
        MouseButtonEvent(12, 18, 0x110, true),
        LayerPopupRegion.content,
      );

      expect(press.isOutsideClick, isTrue);
      expect(release.isOutsideClick, isFalse);
      expect(contentPress.isOutsideClick, isFalse);
    });
  });
}
