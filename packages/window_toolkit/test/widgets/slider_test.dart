import 'package:test/test.dart';
import 'package:window_toolkit/window_toolkit.dart';

import '../support/widget_test_harness.dart';

void main() {
  group('Slider', () {
    test('constructor asserts max > min', () {
      expect(() => Slider(min: 100, max: 50), throwsA(isA<AssertionError>()));
    });

    test('constructor asserts positive dimensions', () {
      expect(() => Slider(trackHeight: 0), throwsA(isA<AssertionError>()));
      expect(() => Slider(thumbRadius: 0), throwsA(isA<AssertionError>()));
    });

    test('value clamped to [min, max]', () {
      final s = Slider(min: 0, max: 100, value: 999);
      expect(s.value, 100);
      final s2 = Slider(min: 0, max: 100, value: -1);
      expect(s2.value, 0);
    });

    test('default range 0-100', () {
      final s = Slider();
      expect(s.min, 0);
      expect(s.max, 100);
    });

    test('onChanged fires', () {
      int calls = 0;
      final s = Slider(onChanged: () => calls++);
      s.onChanged?.call();
      expect(calls, 1);
    });

    test('draw records commands', () {
      final slider = Slider(value: 40);
      final harness = WidgetHarness(slider);
      harness.draw();
      expect(harness.painter.commands, isNotEmpty);

      final value = harness.painter.commands
          .whereType<DrawTextCommand>()
          .single;
      expect(value.position.dx + 16, lessThanOrEqualTo(slider.width));
    });
  });
}
