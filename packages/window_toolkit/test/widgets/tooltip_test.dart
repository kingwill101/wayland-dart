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
test('draws overlay when visible', () {
      final tip = Tooltip(
        text: 'Help',
        child: Button('?'),
      );
      tip.x = 10;
      tip.y = 10;

      final painter = RecordingPainter();
      tip.draw(painter);

      // Initially not visible — no overlay rect
      final before = painter.commands.ofType<DrawRectCommand>().length;

      tip.visible = true;
      painter.clearCommands();
      tip.draw(painter);

      final after = painter.commands.ofType<DrawRectCommand>().length;
      expect(after, greaterThan(before));
    });
  });
}
