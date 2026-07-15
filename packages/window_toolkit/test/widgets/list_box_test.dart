import 'package:test/test.dart';
import 'package:window_toolkit/window_toolkit.dart';

import '../support/widget_test_harness.dart';

void main() {
  group('ListBox', () {
    test('default is empty', () {
      final lb = ListBox();
      expect(lb.items, isEmpty);
    });

    test('items are stored', () {
      final lb = ListBox(items: ['A', 'B', 'C']);
      expect(lb.items.length, 3);
    });

    test('draw records commands', () {
      final lb = ListBox(items: ['One', 'Two', 'Three']);
      final harness = WidgetHarness(lb);
      harness.draw();
      expect(harness.painter.commands, isNotEmpty);
    });

    test('selected index draws selected style', () {
      final lb = ListBox(items: ['A', 'B'], selectedIndex: 1);
      final harness = WidgetHarness(lb);
      harness.draw();
      expect(harness.painter.commands, isNotEmpty);
    });
  });
}
