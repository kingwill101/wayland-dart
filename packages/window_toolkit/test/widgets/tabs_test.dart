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
