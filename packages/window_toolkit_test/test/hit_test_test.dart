import 'package:test/test.dart';
import 'package:window_toolkit/window_toolkit.dart';
import 'package:window_toolkit_test/window_toolkit_test.dart';

void main() {
  group('HitTest with VBox layout', () {
    test('Button inside VBox is clickable at its position', () {
      final harness = TestHarness();
      int clicks = 0;
      final btn = Button('OK', onPressed: () => clicks++);
      harness.pumpWidget(VBox(children: [btn]));
      harness.pump();
      expect(btn.hitTest(btn.x, btn.y), isTrue);
      btn.onClick?.call();
      expect(clicks, 1);
    });

    test('Button hit-test fails outside bounds', () {
      final btn = Button('OK');
      final harness = TestHarness();
      harness.pumpWidget(VBox(children: [btn]));
      harness.pump();
      expect(btn.hitTest(btn.x - 1, btn.y), isFalse);
      expect(btn.hitTest(btn.x + btn.width, btn.y), isFalse);
    });
  });

  group('HitTest with HBox', () {
    test('Multiple buttons are independently hit-testable', () {
      final harness = TestHarness();
      int aClicks = 0, bClicks = 0;
      final btnA = Button('A', onPressed: () => aClicks++);
      final btnB = Button('B', onPressed: () => bClicks++);
      harness.pumpWidget(HBox(spacing: 4, children: [btnA, btnB]));
      harness.pump();

      expect(btnA.hitTest(btnA.x, btnA.y), isTrue);
      btnA.onClick?.call();
      expect(aClicks, 1);
      expect(bClicks, 0);

      expect(btnB.hitTest(btnB.x, btnB.y), isTrue);
      btnB.onClick?.call();
      expect(bClicks, 1);
    });
  });

  group('HitTest with Padding', () {
    test('Button inside Padding is clickable', () {
      final harness = TestHarness();
      int clicks = 0;
      final btn = Button('Pad', onPressed: () => clicks++);
      harness.pumpWidget(Padding(child: btn, left: 10, top: 10, right: 10, bottom: 10));
      harness.pump();
      expect(btn.hitTest(btn.x, btn.y), isTrue);
      btn.onClick?.call();
      expect(clicks, 1);
    });

    test('Padding insets affect hit positions', () {
      final harness = TestHarness();
      final btn = Button('Inset');
      harness.pumpWidget(Padding(child: btn, left: 20, top: 20, right: 20, bottom: 20));
      harness.pump();
      expect(btn.x, 20);
      expect(btn.y, 20);
      expect(btn.hitTest(10, 10), isFalse);
      expect(btn.hitTest(25, 25), isTrue);
    });
  });

  group('HitTest after performLayout (no draw)', () {
    test('Button positions are set after performLayout alone', () {
      final btn = Button('LayoutOnly');
      final vbox = VBox(children: [btn]);
      vbox.performLayout(400);
      expect(btn.x, greaterThanOrEqualTo(0));
      expect(btn.hitTest(btn.x, btn.y), isTrue);
    });
  });

  group('ScrollArea hit tests', () {
    test('ScrollArea child is hit-testable after full layout', () {
      final harness = TestHarness();
      int clicks = 0;
      final btn = Button('Scroll', onPressed: () => clicks++);
      harness.pumpWidget(ScrollArea(child: Padding(child: btn, all: 8)));
      harness.pump();
      expect(btn.x, greaterThanOrEqualTo(8));
      expect(btn.hitTest(btn.x + 2, btn.y + 2), isTrue);
      btn.onClick?.call();
      expect(clicks, 1);
    });

    test('ScrollArea child.x/y set after performLayout', () {
      final btn = Button('Pos');
      final pad = Padding(child: btn, all: 4);
      final scroll = ScrollArea(child: pad);
      scroll.performLayout(200);
      expect(scroll.child.x, 0, reason: 'ScrollArea child.x should be 0 after layout');
      expect(btn.x, greaterThanOrEqualTo(4), reason: 'Button should be inside padding');
    });
  });
}
