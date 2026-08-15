import 'package:test/test.dart';
import 'package:window_toolkit/window_toolkit.dart';

import '../support/widget_test_harness.dart';

void main() {
  group('MouseRegion', () {
    test('child is stored', () {
      final mr = MouseRegion(child: Button('Inside'));
      expect(mr.child, isNotNull);
    });

    test('onTap fires when clicked', () {
      int count = 0;
      final mr = MouseRegion(child: Button('Click'), onTap: () => count++);
      mr.onClick?.call();
      expect(count, 1);
    });

    test('draw records child commands', () {
      final harness = WidgetHarness(MouseRegion(child: Button('OK')));
      harness.draw();
      expect(harness.painter.commands, isNotEmpty);
    });
  });
}
