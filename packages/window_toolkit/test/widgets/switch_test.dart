import 'package:test/test.dart';
import 'package:window_toolkit/window_toolkit.dart';

import '../support/widget_test_harness.dart';

void main() {
  group('Switch', () {
    test('constructor asserts trackWidth > 0', () {
      expect(() => Switch(trackWidth: 0), throwsA(isA<AssertionError>()));
    });
    test('constructor asserts trackHeight > 0', () {
      expect(() => Switch(trackHeight: 0), throwsA(isA<AssertionError>()));
    });

    test('default is off', () {
      expect(Switch().value, isFalse);
    });

    test('toggle flips value', () {
      final sw = Switch();
      sw.toggle();
      expect(sw.value, isTrue);
    });

    test('onChanged fires on toggle', () {
      int count = 0;
      final sw = Switch(onChanged: () => count++);
      sw.onClick?.call();
      expect(count, 1);
    });

    test('hover toggles _hovered state', () {
      final sw = Switch();
      final window = WidgetWindow(sw);
      window.onMouseMotion(MouseMotionEvent(1, 1));
      expect(sw.isHovered, isTrue);
      window.onMouseMotion(MouseMotionEvent(100, 100));
      expect(sw.isHovered, isFalse);
    });

    test('draw records commands', () {
      final harness = WidgetHarness(Switch());
      harness.draw();
      expect(harness.painter.commands, isNotEmpty);
    });
  });
}
