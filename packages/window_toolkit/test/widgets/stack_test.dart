import 'package:test/test.dart';
import 'package:window_toolkit/window_toolkit.dart';

import '../support/widget_test_harness.dart';

void main() {
  group('Stack', () {
    test('empty stack has zero height', () {
      final s = Stack(children: []);
      s.performLayout(400);
      expect(s.height, 0);
    });

    test('children are accessible', () {
      final a = SizedBox(width: 50, height: 30, child: Button('A'));
      final s = Stack(children: [a]);
      expect(s.children.length, 1);
    });

    test('draw records commands', () {
      final harness = WidgetHarness(
        Stack(children: [Button('Back'), Button('Front')]),
      );
      harness.draw();
      expect(harness.painter.commands, isNotEmpty);
    });
  });
}
