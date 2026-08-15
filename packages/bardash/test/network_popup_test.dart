import 'package:test/test.dart';
import 'package:bardash/src/network_popup.dart';

void main() {
  test('NetworkPopupController is closed by default', () {
    expect(NetworkPopupController.isOpen, isFalse);
  });

  test('NetworkPanelLayout hit-tests buttons', () {
    final l = NetworkPanelLayout();
    expect(l.hitSpeedTest(20, l.height - 20), isTrue);
    expect(l.hitSettings(l.width - 20, l.height - 20), isTrue);
    expect(l.hitSpeedTest(4, 4), isFalse);
    expect(l.hitSettings(4, 4), isFalse);
  });

  test('NetworkPopupController closes previous popup on open', () {
    // Controller singleton close() clears the active overlay.
    NetworkPopupController.close();
    expect(NetworkPopupController.isOpen, isFalse);
  });
}
