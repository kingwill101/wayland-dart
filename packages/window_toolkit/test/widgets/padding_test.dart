import 'package:test/test.dart';
import 'package:window_toolkit/window_toolkit.dart';

import '../support/widget_test_harness.dart';

void main() {
  group('Padding', () {
    test('constructor asserts non-negative values', () {
      expect(() => Padding(child: Button('x'), left: -1), throwsA(isA<AssertionError>()));
      expect(() => Padding(child: Button('x'), top: -1), throwsA(isA<AssertionError>()));
    });

    test('constructor accepts all shortcut', () {
      final p = Padding(child: Button('x'), all: 8);
      expect(p.left, 8);
      expect(p.top, 8);
      expect(p.right, 8);
      expect(p.bottom, 8);
    });

    test('performLayout insets child', () {
      final btn = Button('Inset');
      final pad = Padding(child: btn, left: 10, top: 20, right: 10, bottom: 20);
      pad.x = 5;
      pad.y = 5;
      pad.performLayout(400);

      expect(btn.x, 15, reason: 'child.x = parent.x + left');
      expect(btn.y, 25, reason: 'child.y = parent.y + top');
      expect(btn.width, 380, reason: 'child.width = parent.width - left - right');
      expect(pad.height, btn.height + 40, reason: 'parent.height = top + child + bottom');
    });

    test('zero padding passes through', () {
      final btn = Button('Z');
      final pad = Padding(child: btn);
      pad.x = 10;
      pad.y = 10;
      pad.performLayout(200);

      expect(btn.x, 10);
      expect(btn.y, 10);
    });

    test('hitTest inside padding succeeds', () {
      final btn = Button('Hit');
      final pad = Padding(child: btn, all: 8);
      pad.performLayout(400);

      expect(btn.x, 8);
      expect(pad.hitTest(btn.x + 2, btn.y + 2), isTrue,
          reason: 'click on button inside padding');
      expect(pad.hitTest(4, 4), isFalse,
          reason: 'click in padding margin misses button');
    });

    test('draw renders child', () {
      final harness = WidgetHarness(Padding(
        child: Button('Padded'),
        all: 12,
      ));
      harness.draw();
      final commands = harness.painter.commands;
      expect(commands, isNotEmpty);
    });
  });
}
