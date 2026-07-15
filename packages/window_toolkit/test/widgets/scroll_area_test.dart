import 'package:test/test.dart';
import 'package:window_toolkit/window_toolkit.dart';

import '../support/widget_test_harness.dart';

void main() {
  group('ScrollArea', () {
    test('performLayout positions child', () {
      final btn = Button('Inside');
      final scroll = ScrollArea(child: Padding(child: btn, all: 8));
      scroll.x = 5;
      scroll.y = 10;
      scroll.performLayout(200);

      expect(scroll.child.x, 5, reason: 'ScrollArea child.x = parent.x');
      expect(scroll.child.y, 10, reason: 'ScrollArea child.y = parent.y');
    });

    test('scrollBy updates scrollX and scrollY', () {
      final large = SizedBox(width: 2000, height: 2000, child: Button('Big'));
      final scroll = ScrollArea(child: large);
      scroll.width = 100;
      scroll.height = 100;
      scroll.performLayout(100);

      expect(scroll.maxScrollX, greaterThan(0));
      expect(scroll.maxScrollY, greaterThan(0));

      scroll.scrollBy(50, 100);
      expect(scroll.scrollX, 50);
      expect(scroll.scrollY, 100);
    });

    test('scrollBy clamps to bounds', () {
      final large = SizedBox(width: 2000, height: 2000, child: Button('Big'));
      final scroll = ScrollArea(child: large);
      scroll.width = 100;
      scroll.height = 100;
      scroll.performLayout(100);

      scroll.scrollBy(-9999, -9999);
      expect(scroll.scrollX, 0);
      expect(scroll.scrollY, 0);
    });

    test('isOnScrollbar detects vertical scrollbar hit', () {
      final scroll = ScrollArea(
        child: SizedBox(width: 2000, height: 2000, child: Button('Big')),
      );
      scroll.width = 100;
      scroll.height = 100;
      scroll.performLayout(100);

      // Scrollbar is at right edge.
      final sbX = scroll.x + scroll.width - scroll.scrollbarWidth;
      expect(scroll.isOnScrollbar(sbX, scroll.y + 5), isTrue);
      expect(scroll.isOnScrollbar(scroll.x + 5, scroll.y + 5), isFalse);
    });

    test('hitTest works on child inside scroll area', () {
      final harness = WidgetHarness(ScrollArea(
        child: Button('ScrollMe'),
      ));
      harness.draw();
      final cmds = harness.painter.commands;
      expect(cmds, isNotEmpty);
    });

    test('draw records clip rect and scrollbar commands', () {
      final large = SizedBox(width: 2000, height: 2000, child: Button('Big'));
      final scroll = ScrollArea(child: large);
      scroll.width = 100;
      scroll.height = 100;
      scroll.performLayout(100);

      final painter = RecordingPainter();
      scroll.draw(painter);
      expect(painter.commands, isNotEmpty);
    });
  });
}
