import 'package:test/test.dart';
import 'package:window_toolkit/window_toolkit.dart';

import '../support/widget_test_harness.dart';

void main() {
  group('TabBar', () {
    test('default labels is empty', () {
      final tb = TabBar();
      expect(tb.labels, isEmpty);
    });

    test('tabs are drawn', () {
      final harness = WidgetHarness(TabBar(
        labels: ['One', 'Two', 'Three'],
        activeIndex: 0,
      ));
      harness.draw();
      expect(harness.painter.commands, isNotEmpty);
    });

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

  group('TabView', () {
    test('pages are stored', () {
      final tv = TabView(
        header: TabBar(labels: ['A', 'B']),
        pages: [Label('Page A'), Label('Page B')],
      );
      expect(tv.children.length, 2);
    });

    test('draw records commands', () {
      final harness = WidgetHarness(TabView(
        header: TabBar(labels: ['X', 'Y']),
        pages: [Button('X'), Button('Y')],
      ));
      harness.draw();
      expect(harness.painter.commands, isNotEmpty);
    });
  });
}
