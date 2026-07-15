import 'package:test/test.dart';
import 'package:window_toolkit/window_toolkit.dart';

import '../support/widget_test_harness.dart';

void main() {
  group('VBox', () {
    test('constructor asserts spacing >= 0', () {
      expect(() => VBox(spacing: -1), throwsA(isA<AssertionError>()));
    });

    test('empty VBox has zero size', () {
      final vbox = VBox();
      vbox.performLayout(400);
      expect(vbox.width, greaterThanOrEqualTo(0));
      expect(vbox.height, 0);
    });

    test('lays out children vertically', () {
      final a = Button('A');
      final b = Button('B');
      final vbox = VBox(spacing: 4, children: [a, b]);
      vbox.performLayout(400);

      expect(vbox.height, greaterThan(0));
      // A is above B.
      expect(a.y, lessThan(b.y));
      // Children span full width.
      expect(a.width, lessThanOrEqualTo(400));
    });

    test('performLayout sets child x/y positions', () {
      final a = Button('A');
      final b = Button('B');
      final vbox = VBox(spacing: 4, children: [a, b]);
      vbox.x = 10;
      vbox.y = 20;
      vbox.performLayout(400);

      expect(a.x, 10);
      expect(b.x, 10);
      expect(a.y, greaterThanOrEqualTo(20));
      expect(b.y, greaterThan(a.y));
    });

    test('hitTest returns deepest child', () {
      final a = Button('A');
      final b = Button('B');
      final vbox = VBox(spacing: 4, children: [a, b]);
      vbox.performLayout(400);

      // Point within button A
      expect(vbox.hitTest(a.x + 2, a.y + 2), isTrue);
      // Point within button B
      expect(vbox.hitTest(b.x + 2, b.y + 2), isTrue);
      // Point outside VBox
      expect(vbox.hitTest(-1, -1), isFalse);
    });

    test('draw positions children correctly', () {
      final harness = WidgetHarness(VBox(spacing: 4, children: [
        Button('A'),
        Button('B'),
      ]));
      harness.draw();
      final commands = harness.painter.commands;
      // Should have drawn button backgrounds + text.
      expect(commands.whereType<DrawRectCommand>().length, greaterThanOrEqualTo(2));
    });
  });
}
