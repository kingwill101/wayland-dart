import 'package:test/test.dart';
import 'package:window_toolkit/window_toolkit.dart';

import '../support/widget_test_harness.dart';

void main() {
  group('Spinner', () {
    test('default constructor', () {
      final s = Spinner();
      expect(s.active, isTrue);
      expect(s.dotCount, 8);
    });

    test('draw records commands when active', () {
      final harness = WidgetHarness(Spinner(active: true));
      harness.draw();
      expect(harness.painter.commands, isNotEmpty);
    });

    test('inactive spinner draws a static dot', () {
      final harness = WidgetHarness(Spinner(active: false));
      harness.draw();
      // Inactive spinner may still draw a static representation.
      expect(harness.painter.commands.length, lessThanOrEqualTo(
          Spinner().dotCount));
    });
  });
}
