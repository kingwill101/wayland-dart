import 'package:test/test.dart';
import 'package:window_toolkit/window_toolkit.dart';
import 'package:bardash/src/network_popup.dart';
import 'package:bardash/src/native/network_manager.dart';

void main() {
  setUp(StyleContext.reset);

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

  test('NetworkPanelWidget uses toolkit children and keeps actions inside', () {
    final panel = NetworkPanelWidget(onSpeedTest: () {}, onSettings: () {});
    final painter = RecordingPainter(width: 260, height: 190);

    panel.update(
      snapshot: const NmSnapshot(
        connected: true,
        type: 'wifi',
        ifname: 'wlp0s20f3',
        ip4: '192.168.50.158',
        ssid: 'LIB-0120750',
        signal: 80,
        connectionId: 'LIB-0120750',
      ),
      down: '165.3 KB/s',
      up: '12.0 KB/s',
    );
    panel.measure(painter);
    panel.performLayout(panel.panelWidth);

    expect(panel.children, contains(panel.title));
    expect(panel.children, contains(panel.speedTestButton));
    expect(panel.children, contains(panel.settingsButton));
    expect(panel.title.text, 'LIB-0120750');
    expect(panel.downloadValue.text, '165.3 KB/s');
    expect(panel.uploadValue.text, '12.0 KB/s');
    expect(
      panel.settingsButton.x + panel.settingsButton.width,
      lessThanOrEqualTo(panel.width),
    );
    expect(
      panel.settingsButton.y + panel.settingsButton.height,
      lessThanOrEqualTo(panel.height),
    );
    expect(
      panel.buttonAt(panel.settingsButton.x + 2, panel.settingsButton.y + 2),
      same(panel.settingsButton),
    );
  });

  test('NetworkPanelWidget actions expose CSS and hover state', () {
    final provider = CssProvider()
      ..loadFromData(
        '#network-popup { background-color: #112233; } '
        '#network-settings:hover { background-color: #445566; }',
      );
    StyleContext.addProviderForScreen(provider);
    final panel = NetworkPanelWidget(onSpeedTest: () {}, onSettings: () {});
    final painter = RecordingPainter(width: 260, height: 190);
    panel.measure(painter);
    panel.performLayout(panel.panelWidth);
    panel.updateButtonHover(
      panel.settingsButton.x + 2,
      panel.settingsButton.y + 2,
    );

    expect(panel.settingsButton.isHovered, isTrue);
    final panelBackground = panel.resolvedStyle().backgroundColor!;
    expect(
      (panelBackground.r, panelBackground.g, panelBackground.b),
      (17, 34, 51),
    );
    final buttonBackground = panel.settingsButton
        .resolvedStyle()
        .backgroundColor!;
    expect(
      (buttonBackground.r, buttonBackground.g, buttonBackground.b),
      (68, 85, 102),
    );
  });
}
