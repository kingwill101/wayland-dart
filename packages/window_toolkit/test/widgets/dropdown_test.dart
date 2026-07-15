import 'package:test/test.dart';
import 'package:window_toolkit/window_toolkit.dart';

import '../support/widget_test_harness.dart';

void main() {
  group('Dropdown', () {
    test('default is closed with empty items', () {
      final dd = Dropdown();
      expect(dd.opened, isFalse);
      expect(dd.items, isEmpty);
    });

    test('items are stored', () {
      final dd = Dropdown(items: ['A', 'B', 'C']);
      expect(dd.items.length, 3);
    });

    test('selection index is stored', () {
      final dd = Dropdown(items: ['X', 'Y', 'Z'], selectedIndex: 1);
      expect(dd.selectedIndex, 1);
    });

    test('draw records commands', () {
      final harness = WidgetHarness(Dropdown(items: ['One', 'Two']));
      harness.draw();
      expect(harness.painter.commands, isNotEmpty);
    });

    test('opened dropdown draws items', () {
      final harness = WidgetHarness(Dropdown(
        items: ['Red', 'Green', 'Blue'],
        opened: true,
      ));
      harness.draw();
      expect(harness.painter.commands, isNotEmpty);
    });
  });
}
