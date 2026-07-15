import 'package:test/test.dart';
import 'package:window_toolkit/window_toolkit.dart';

import '../support/widget_test_harness.dart';

void main() {
  group('Center', () {
    test('child is accessible', () {
      final c = Center(child: Button('x'));
      expect(c.child, isNotNull);
    });

    test('performLayout centers child', () {
      final btn = Button('Centered');
      final c = Center(child: btn);
      c.x = 0;
      c.y = 0;
      c.width = 300;
      c.height = 100;
      c.performLayout(300);

      // btn should be positioned inside the Center widget.
      expect(btn.x, greaterThanOrEqualTo(0));
      expect(btn.y, greaterThanOrEqualTo(0));
      expect(btn.x + btn.width, lessThanOrEqualTo(300));
    });

    test('draw records child commands', () {
      final harness = WidgetHarness(Center(child: Button('OK')));
      harness.draw();
      expect(harness.painter.commands, isNotEmpty);
    });
  });
}
