import 'package:test/test.dart';
import 'package:window_toolkit/window_toolkit.dart';

import '../support/widget_test_harness.dart';

void main() {
  group('DecoratedBox', () {
    test('color applies to background', () {
      final db = DecoratedBox(color: const Color(255, 0, 0));
      final harness = WidgetHarness(db);
      harness.draw();
      final rects = harness.painter.commands.ofType<DrawRectCommand>();
      expect(rects, isNotEmpty);
    });

    test('borderWidth > 0 draws border', () {
      final db = DecoratedBox(
        borderWidth: 2,
        borderColor: const Color(0, 0, 0),
      );
      final harness = WidgetHarness(db);
      harness.draw();
      expect(harness.painter.commands, isNotEmpty);
    });

    test('draws child when provided', () {
      final db = DecoratedBox(
        child: Button('Inside'),
        color: const Color(50, 50, 50),
      );
      final harness = WidgetHarness(db);
      harness.draw();
      expect(harness.painter.commands, isNotEmpty);
    });
  });
}
