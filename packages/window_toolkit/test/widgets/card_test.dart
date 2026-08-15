import 'package:test/test.dart';
import 'package:window_toolkit/window_toolkit.dart';

import '../support/widget_test_harness.dart';

void main() {
  group('Card', () {
    test('default color is dark', () {
      final c = Card();
      expect(c.backgroundColor.r, 28);
      expect(c.backgroundColor.g, 28);
      expect(c.backgroundColor.b, 28);
    });

    test('children list is mutable', () {
      final c = Card(children: [Button('A')]);
      expect(c.children.length, 1);
      c.children.add(Button('B'));
      expect(c.children.length, 2);
    });

    test('title is displayed when set', () {
      final harness = WidgetHarness(
        Card(title: 'Test Card', children: [Button('OK')]),
      );
      harness.draw();
      final texts = harness.painter.commands.ofType<DrawTextCommand>();
      expect(texts, isNotEmpty);
    });

    test('draw records commands', () {
      final harness = WidgetHarness(Card(children: [Button('Inside')]));
      harness.draw();
      expect(harness.painter.commands, isNotEmpty);
    });
  });
}
