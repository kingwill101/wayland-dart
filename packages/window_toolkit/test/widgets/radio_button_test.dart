import 'package:test/test.dart';
import 'package:window_toolkit/window_toolkit.dart';

import '../support/widget_test_harness.dart';

void main() {
  group('RadioButton', () {
    test('default is not selected', () {
      final rb = RadioButton('Opt');
      expect(rb.selected, isFalse);
    });

    test('click selects', () {
      final rb = RadioButton('Opt');
      rb.onClick?.call();
      expect(rb.selected, isTrue);
    });

    test('draw records commands', () {
      final harness = WidgetHarness(RadioButton('Test'));
      harness.draw();
      expect(harness.painter.commands, isNotEmpty);
    });
  });
}
