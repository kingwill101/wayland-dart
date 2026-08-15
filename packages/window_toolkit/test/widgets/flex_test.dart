import 'package:test/test.dart';
import 'package:window_toolkit/window_toolkit.dart';

import '../support/widget_test_harness.dart';

void main() {
  group('Flex', () {
    test('Flexible requires child', () {
      expect(Flexible(child: Button('x')).child, isNotNull);
    });

    test('Flex horizontal performLayout sizes children', () {
      final a = Button('A');
      final b = Button('B');
      final flex = Flex(direction: Axis.horizontal, children: [a, b]);
      flex.performLayout(400);
      // Children are sized, positions depend on Flex.layout (called in draw).
      expect(a.width, greaterThan(0));
      expect(b.width, greaterThan(0));
    });

    test('draw records commands', () {
      final harness = WidgetHarness(
        Flex(
          direction: Axis.horizontal,
          children: [Button('Left'), Button('Right')],
        ),
      );
      harness.draw();
      expect(harness.painter.commands, isNotEmpty);
    });
  });
}
