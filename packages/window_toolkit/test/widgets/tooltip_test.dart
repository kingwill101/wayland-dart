import 'package:test/test.dart';
import 'package:window_toolkit/window_toolkit.dart';

import '../support/widget_test_harness.dart';

void main() {
  group('Tooltip', () {
    test('constructor stores text', () {
      final t = Tooltip(text: 'Help', child: Button('OK'));
      expect(t.text, 'Help');
    });

    test('child is accessible', () {
      final t = Tooltip(text: 'Tip', child: Button('OK'));
      expect(t.child, isNotNull);
    });

    test('draw records child commands', () {
      final harness = WidgetHarness(Tooltip(text: 'Tip', child: Button('OK')));
      harness.draw();
      expect(harness.painter.commands, isNotEmpty);
    });
  });
}
