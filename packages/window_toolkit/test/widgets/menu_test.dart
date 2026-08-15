import 'package:test/test.dart';
import 'package:window_toolkit/window_toolkit.dart';

import '../support/widget_test_harness.dart';

void main() {
  group('Menu', () {
    test('menu item has text', () {
      final mi = MenuItem('Save');
      expect(mi.label, 'Save');
    });

    test('menu item fires onTriggered', () {
      int count = 0;
      final mi = MenuItem('Save', onTriggered: () => count++);
      mi.onTriggered?.call();
      expect(count, 1);
    });

    test('menu draws items', () {
      final menu = Menu(
        items: [MenuItem('Open'), MenuItem('Save'), MenuItem('Quit')],
      );
      final harness = WidgetHarness(menu);
      harness.draw();
      expect(harness.painter.commands, isNotEmpty);
    });
  });
}
