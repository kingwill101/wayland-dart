import 'package:test/test.dart';
import 'package:window_toolkit/window_toolkit.dart';

import '../support/widget_test_harness.dart';

void main() {
  group('SizedBox', () {
    test('fixed width and height', () {
      final sb = SizedBox(width: 100, height: 50);
      expect(sb.width, 100);
      expect(sb.height, 50);
    });

    test('child is sized by SizedBox', () {
      final sb = SizedBox(width: 200, height: 100, child: Button('Inside'));
      final harness = WidgetHarness(sb);
      harness.draw();
      expect(harness.painter.commands, isNotEmpty);
    });

    test('performLayout propagates to child', () {
      final btn = Button('Test');
      final sb = SizedBox(width: 300, height: 50, child: btn);
      sb.performLayout(400);
      expect(btn.width, 300, reason: 'child gets SizedBox width');
    });
  });
}
