import 'package:test/test.dart';
import 'package:window_toolkit/window_toolkit.dart';

import '../support/widget_test_harness.dart';

void main() {
  group('Badge', () {
    test('default count is 0', () {
      final b = Badge();
      expect(b.count, 0);
    });

    test('sets width from label text', () {
      final b = Badge(label: '99+');
      expect(b.width, greaterThan(0));
    });

    test('draw with label records commands', () {
      final harness = WidgetHarness(Badge(label: '3'));
      harness.draw();
      expect(harness.painter.commands, isNotEmpty);
    });

    test('draw with count records commands', () {
      final harness = WidgetHarness(Badge(count: 7));
      harness.draw();
      expect(harness.painter.commands, isNotEmpty);
    });
  });
}
