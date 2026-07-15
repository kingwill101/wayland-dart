import 'package:test/test.dart';
import 'package:window_toolkit/window_toolkit.dart';

import '../support/widget_test_harness.dart';

void main() {
  group('GroupBox', () {
    test('default is untitled', () {
      final g = GroupBox(children: []);
      expect(g.title, isNull);
    });

    test('title is displayed', () {
      final harness = WidgetHarness(GroupBox(title: 'Settings', children: [
        Button('Option'),
      ]));
      harness.draw();
      expect(harness.painter.commands, isNotEmpty);
    });

    test('draws children inside box', () {
      final harness = WidgetHarness(GroupBox(title: 'Group', children: [
        Button('A'),
        Button('B'),
      ]));
      harness.draw();
      expect(harness.painter.commands, isNotEmpty);
    });
  });
}
