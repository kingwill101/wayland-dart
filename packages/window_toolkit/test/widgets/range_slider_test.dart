import 'package:test/test.dart';
import 'package:window_toolkit/window_toolkit.dart';

import '../support/widget_test_harness.dart';

void main() {
  group('RangeSlider', () {
    test('default range 0-100', () {
      final rs = RangeSlider();
      expect(rs.min, 0);
      expect(rs.max, 100);
    });

    test('draw records commands', () {
      final harness = WidgetHarness(RangeSlider());
      harness.draw();
      expect(harness.painter.commands, isNotEmpty);
    });
  });
}
