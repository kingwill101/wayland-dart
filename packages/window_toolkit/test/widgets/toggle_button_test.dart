import 'package:test/test.dart';
import 'package:window_toolkit/window_toolkit.dart';

import '../support/widget_test_harness.dart';

void main() {
  group('ToggleButton', () {
    test('default is not selected', () {
      final tb = ToggleButton('Off');
      expect(tb.selected, isFalse);
    });

    test('click toggles selection', () {
      final tb = ToggleButton('Toggle');
      tb.onClick?.call();
      expect(tb.selected, isTrue);
    });

    test('onChanged fires on toggle', () {
      int count = 0;
      final tb = ToggleButton('T', onChanged: () => count++);
      tb.onClick?.call();
      expect(count, 1);
    });

    test('draw records commands', () {
      final harness = WidgetHarness(ToggleButton('Test'));
      harness.draw();
      expect(harness.painter.commands, isNotEmpty);
    });
  });
}
