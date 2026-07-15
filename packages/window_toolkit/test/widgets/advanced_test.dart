import 'package:test/test.dart';
import 'package:window_toolkit/window_toolkit.dart';

import '../support/widget_test_harness.dart';

void main() {
  group('ScrollArea', () {
    test('clips child and draws scrollbar when content overflows', () {
      final content = Label('Tall content')..height = 200;
      final scroll = ScrollArea(
        child: content,
        scrollY: 20,
      );
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
        ..height = 20;
      final scroll = ScrollArea(
        child: content,
        scrollX: 50,
      );
      scroll.x = 0;
      scroll.y = 0;
      scroll.width = 100;
      scroll.height = 30;

      // Child at scrollX=50 means child x=50 is at screen x=0
      expect(scroll.hitTest(0, 5), isTrue);
      expect(scroll.hitTest(200, 5), isFalse);
    });
  });

  group('TextField', () {
    test('draws cursor at correct position', () {
      final ctrl = TextEditingController(text: 'hello');
      ctrl.cursor = 3;
      final tf = TextField(controller: ctrl);
      tf.x = 10;
      tf.y = 10;
      tf.width = 120;
      tf.height = 24;
      tf.onClick?.call(); // gain focus

      final painter = RecordingPainter();
      tf.draw(painter);

      final lines = painter.commands.ofType<DrawLineCommand>().toList();
      expect(lines, hasLength(1));
      expect(lines.single.from.dx, 38);
    });

    test('insert, delete, and cursor navigation work', () {
      final ctrl = TextEditingController(text: 'hi');
      ctrl.cursor = 2;
      ctrl.insert('!');
      expect(ctrl.text, 'hi!');
      expect(ctrl.cursor, 3);

      ctrl.moveCursorLeft();
      expect(ctrl.cursor, 2);

      ctrl.deleteLeft();
      expect(ctrl.text, 'h!');
      expect(ctrl.cursor, 1);
    });
  });

  group('TabBar', () {
    test('draws tabs and indicator at active index', () {
      final tabs = TabBar(
        labels: ['One', 'Two'],
        activeIndex: 0,
      );
      tabs.x = 5;
      tabs.y = 6;
      tabs.width = 120;
      tabs.height = 28;

      final painter = RecordingPainter();
      tabs.draw(painter);

      final rects = painter.commands.ofType<DrawRectCommand>().toList();
      expect(rects, hasLength(3));
      expect(tabs.tabAt(10, 15), 0);
      expect(tabs.tabAt(70, 15), 1);
      expect(tabs.tabAt(200, 15), -1);
    });
  });

  group('Tooltip', () {
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

  test('ScrollArea wheel scrolls composite tree with Flex/Row/Column', () {
    // Replicate the showcase pattern: a composite tree inside ScrollArea
    final content = VBoxLayout(
      spacing: 8,
      children: [
        Row(spacing: 8, children: [
          Expanded(child: Button('Wide')),
          Button('AB'),
        ]),
        Column(spacing: 6, children: [
          Flexible(child: Label('Top')),
          Expanded(child: Button('Fill')),
          Label('Bottom'),
        ]),
        Padding(all: 12, child: Row(children: [
          Button('L'),
          Spacer(),
          Button('R'),
        ])),
        WrapLayout(spacing: 4, children: [
          Button('A'), Button('B'), Button('C'),
        ]),
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

    // Draw once — triggers performLayout throughout the tree
    final painter = RecordingPainter();
    scroll.draw(painter);

    // Must have scrollable content
    expect(scroll.maxScrollY, greaterThan(0),
      reason: 'content height must exceed viewport for scrolling');

    // Direct onMouseWheel call — this is what WidgetWindow routes to
    final before = scroll.scrollY;
    scroll.onMouseWheel(MouseWheelEvent(10, 10, 0, 40));
    expect(scroll.scrollY, greaterThan(before),
      reason: 'wheel down should increase scrollY');

    // Can scroll to bottom
    while (scroll.scrollY < scroll.maxScrollY) {
      scroll.onMouseWheel(MouseWheelEvent(10, 10, 0, 40));
    }
    expect(scroll.scrollY, scroll.maxScrollY,
      reason: 'should reach maxScrollY at bottom');
  });
}
