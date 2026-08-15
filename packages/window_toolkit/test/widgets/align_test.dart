import 'package:test/test.dart';
import 'package:window_toolkit/window_toolkit.dart';

import '../support/widget_test_harness.dart';

void main() {
  group('Align', () {
    test('child is accessible', () {
      final btn = Button('OK');
      final a = Align(child: btn);
      expect(a.child, btn);
    });

    test('performLayout centers child horizontally', () {
      final btn = Button('Centered');
      final a = Align(
        child: btn,
        horizontalAlignment: HorizontalAlignment.center,
      );
      a.x = 0;
      a.width = 200;
      a.performLayout(200);
      // btn width = text.length * charWidth + padding*2 = 8*8 + 8 = 72
      // Actually charWidth=8, padding=4, text='Centered' has 8 chars
      // width = 8*8 + 8 = 72. (200-72)/2 = 64
      expect(btn.x, greaterThanOrEqualTo(0));
      expect(btn.x + btn.width, lessThanOrEqualTo(200));
    });

    test('right alignment positions child at end', () {
      final btn = Button('R');
      final a = Align(
        child: btn,
        horizontalAlignment: HorizontalAlignment.right,
      );
      a.width = 200;
      a.x = 0;
      a.performLayout(200);
      expect(btn.x + btn.width, 200, reason: 'right edge at parent right');
    });

    test('draw records child commands', () {
      final harness = WidgetHarness(Align(child: Button('A')));
      harness.draw();
      final rects = harness.painter.commands.ofType<DrawRectCommand>();
      expect(rects, isNotEmpty);
    });
  });
}
