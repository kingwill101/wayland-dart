import 'package:test/test.dart';
import 'package:window_toolkit/window_toolkit.dart';

import '../support/widget_test_harness.dart';

void main() {
  group('Checkbox', () {
    test('constructor asserts boxSize > 0', () {
      expect(() => Checkbox(boxSize: 0), throwsA(isA<AssertionError>()));
    });

    test('default unchecked', () {
      final cb = Checkbox();
      expect(cb.checked, isFalse);
    });

    test('toggle flips state', () {
      final cb = Checkbox();
      cb.toggle();
      expect(cb.checked, isTrue);
      cb.toggle();
      expect(cb.checked, isFalse);
    });

    test('onChanged fires on toggle', () {
      int calls = 0;
      final cb = Checkbox(onChanged: () => calls++);
      cb.toggle();
      expect(calls, 1);
    });

    test('size from boxSize', () {
      final cb = Checkbox(boxSize: 24);
      expect(cb.width, 24);
      expect(cb.height, 24);
    });

    test('draw records rect commands', () {
      final harness = WidgetHarness(Checkbox());
      harness.draw();
      expect(harness.painter.commands.length, greaterThan(0));
    });
  });
}
