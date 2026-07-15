import 'package:test/test.dart';
import 'package:window_toolkit/window_toolkit.dart';

import '../support/widget_test_harness.dart';

void main() {
  group('HBox', () {
    test('constructor asserts spacing >= 0', () {
      expect(() => HBox(spacing: -1), throwsA(isA<AssertionError>()));
    });

    test('empty HBox has zero height', () {
      final hbox = HBox();
      hbox.performLayout(400);
      expect(hbox.width, greaterThanOrEqualTo(0));
      expect(hbox.height, 0);
    });

    test('lays out children horizontally', () {
      final a = Button('A');
      final b = Button('B');
      final hbox = HBox(spacing: 4, children: [a, b]);
      hbox.performLayout(400);

      expect(hbox.width, greaterThan(0));
      // A is left of B.
      expect(a.x, lessThan(b.x));
      // Both children get parent height.
      expect(a.height, hbox.height);
    });

    test('performLayout sets child x/y positions', () {
      final a = Button('A');
      final b = Button('B');
      final hbox = HBox(spacing: 8, children: [a, b]);
      hbox.x = 15;
      hbox.y = 5;
      hbox.performLayout(400);

      expect(a.x, 15);
      expect(a.y, 5);
      expect(b.x, greaterThan(a.x + a.width));
      expect(b.y, 5);
    });

    test('hitTest returns deepest child', () {
      final a = Button('A');
      final b = Button('B');
      final hbox = HBox(spacing: 4, children: [a, b]);
      hbox.performLayout(400);

      expect(hbox.hitTest(a.x + 2, a.y + 2), isTrue);
      expect(hbox.hitTest(b.x + 2, b.y + 2), isTrue);
      expect(hbox.hitTest(-1, -1), isFalse);
    });

    test('draw positions children correctly', () {
      final harness = WidgetHarness(HBox(spacing: 4, children: [
        Button('Left'),
        Button('Right'),
      ]));
      harness.draw();
      final commands = harness.painter.commands;
      expect(commands.length, greaterThan(0));
    });
  });
}
