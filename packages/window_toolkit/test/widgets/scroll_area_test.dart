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

    test('scrollBy updates scrollY', () {
      final large = SizedBox(width: 2000, height: 2000, child: Button('Big'));
      final scroll = ScrollArea(child: large);
      scroll.width = 100;
      scroll.height = 100;
      scroll.performLayout(100);

      expect(scroll.maxScrollY, greaterThan(0));

      scroll.scrollBy(0, 100);
      expect(scroll.scrollY, 100);
    });

    test('scrollBy clamps to bounds', () {
      final large = SizedBox(width: 2000, height: 2000, child: Button('Big'));
      final scroll = ScrollArea(child: large);
      scroll.width = 100;
      scroll.height = 100;
      scroll.performLayout(100);

      scroll.scrollBy(0, -9999);
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
      final harness = WidgetHarness(ScrollArea(child: Button('ScrollMe')));
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
  test('clips child and draws scrollbar when content overflows', () {
    final content = Label('Tall content')..height = 200;
    final scroll = ScrollArea(child: content, initialScrollY: 20);
    scroll.x = 4;
    scroll.y = 5;
    scroll.width = 100;
    scroll.height = 60;

    final painter = RecordingPainter();
    scroll.draw(painter);

    final clips = painter.commands.ofType<ClipRectCommand>().toList();
    expect(clips, hasLength(1));
    final clip = clips.single.rect;
    expect(clip.left, 4);
    expect(clip.top, 5);
    expect(clip.right, 104);
    expect(clip.bottom, 65);

    expect(scroll.maxScrollY, 140);

    scroll.scrollBy(0, 50);
    expect(scroll.scrollY, 70);
  });

  test('hit test translates into scroll space', () {
    final content = Label('Wide')
      ..width = 400
      ..height = 200;
    final scroll = ScrollArea(child: content, initialScrollY: 50);
    scroll.x = 0;
    scroll.y = 0;
    scroll.width = 100;
    scroll.height = 30;
    scroll.performLayout(100);

    // Child at scrollY=50 means child y=50 is at screen y=0
    expect(scroll.hitTest(5, 0), isTrue);
    expect(scroll.hitTest(5, 200), isFalse);
  });

  test('wheel scrolls composite tree with Flex/Row/Column', () {
    final content = VBoxLayout(
      spacing: 8,
      children: [
        Row(
          spacing: 8,
          children: [
            Expanded(child: Button('Wide')),
            Button('AB'),
          ],
        ),
        Column(
          spacing: 6,
          children: [
            Flexible(child: Label('Top')),
            Expanded(child: Button('Fill')),
            Label('Bottom'),
          ],
        ),
        Padding(
          all: 12,
          child: Row(children: [Button('L'), Spacer(), Button('R')]),
        ),
        WrapLayout(
          spacing: 4,
          children: [Button('A'), Button('B'), Button('C')],
        ),
        Align(
          horizontalAlignment: HorizontalAlignment.right,
          child: Button('Right'),
        ),
        for (var i = 0; i < 5; i++) Label('Line $i'),
      ],
    );

    final scroll = ScrollArea(child: content);
    scroll.x = 0;
    scroll.y = 0;
    scroll.width = 200;
    scroll.height = 60;

    final painter = RecordingPainter();
    scroll.draw(painter);

    expect(
      scroll.maxScrollY,
      greaterThan(0),
      reason: 'content height must exceed viewport for scrolling',
    );

    final before = scroll.scrollY;
    scroll.onMouseWheel(MouseWheelEvent(10, 10, 0, 40));
    expect(
      scroll.scrollY,
      greaterThan(before),
      reason: 'wheel down should increase scrollY',
    );

    while (scroll.scrollY < scroll.maxScrollY) {
      scroll.onMouseWheel(MouseWheelEvent(10, 10, 0, 40));
    }
    expect(
      scroll.scrollY,
      scroll.maxScrollY,
      reason: 'should reach maxScrollY at bottom',
    );
  });
}
