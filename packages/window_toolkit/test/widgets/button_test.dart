import 'package:test/test.dart';
import 'package:window_toolkit/window_toolkit.dart';

import '../support/widget_test_harness.dart';

void main() {
  group('Button', () {
    test('constructor asserts non-empty text', () {
      expect(() => Button(''), throwsA(isA<AssertionError>()));
    });

    test('constructor asserts positive dimensions', () {
      expect(() => Button('x', charWidth: 0), throwsA(isA<AssertionError>()));
      expect(() => Button('x', charHeight: 0), throwsA(isA<AssertionError>()));
    });

    test('constructor sets size from text', () {
      final btn = Button('OK');
      expect(btn.width, greaterThan(0));
      expect(btn.height, greaterThan(0));
    });

    test('onClick fires when pressed', () {
      int count = 0;
      final btn = Button('OK', onPressed: () => count++);
      btn.onClick?.call();
      expect(count, 1);
    });

    test('hover state toggles on mouse enter/leave', () {
      bool hovered = false;
      final btn = Button('Hover');
      btn.onMouseEnter = () {
        hovered = true;
      };
      btn.onMouseLeave = () {
        hovered = false;
      };

      btn.onMouseEnter?.call();
      expect(hovered, isTrue);

      btn.onMouseLeave?.call();
      expect(hovered, isFalse);
    });

    test('setHovering drives the canonical animated hover state', () {
      final btn = Button('Hover');

      btn.setHovering(true);
      expect(btn.isHovered, isTrue);
      expect(btn.hasPseudoClass('hover'), isTrue);

      btn.setHovering(false);
      expect(btn.isHovered, isFalse);
      expect(btn.hasPseudoClass('hover'), isFalse);
    });

    test('hover state requests a repaint', () {
      final btn = Button('Repaint');
      final previous = Widget.onNeedsRepaint;
      var repaints = 0;
      Widget.onNeedsRepaint = () => repaints++;
      try {
        btn.setHovering(true);
        expect(repaints, greaterThan(0));
      } finally {
        Widget.onNeedsRepaint = previous;
      }
    });

    test('draw records rect and text commands', () {
      final harness = WidgetHarness(Button('OK'));
      harness.draw();
      final rects = harness.painter.commands.ofType<DrawRectCommand>();
      expect(rects, hasLength(1));
      final texts = harness.painter.commands.ofType<DrawTextCommand>();
      expect(texts, hasLength(1));
      expect(texts.first.text, 'OK');
    });

    test('hitTest succeeds within bounds', () {
      final btn = Button('Hit');
      btn.x = 10;
      btn.y = 10;
      expect(btn.hitTest(12, 12), isTrue);
      expect(btn.hitTest(5, 12), isFalse);
    });
  });
}
