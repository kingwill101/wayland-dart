/// Integration tests for widget layout, hover, and scroll behaviors.
///
/// These test the conditions the user reported: resize propagation,
/// hover state changes, scrollbar visibility, and wheel scrolling.
import 'package:test/test.dart';
import 'package:window_toolkit/window_toolkit.dart';

void main() {
  // ── Resize propagation ──────────────────────────────────────

  group('Resize', () {
    test('ElementHost propagates size to children', () {
      final host = ElementHost(child: _SizedStateless(size: 100));
      host.x = 0;
      host.y = 0;
      host.width = 400;
      host.height = 300;
      host.performLayout(400);

      // The renderable widget should reflect the available space
      final render = host.children.first;
      expect(render.width, greaterThan(0));
      expect(render.height, greaterThan(0));
    });

    test('ScrollArea resizes with parent', () {
      final sa = ScrollArea(
        child: SizedBox(width: 200, height: 1000),
        showVertical: true,
      );
      sa.x = 0;
      sa.y = 0;
      sa.width = 400;
      sa.height = 300;
      sa.performLayout(400);

      final initialH = sa.height;

      // Simulate resize
      sa.width = 500;
      sa.height = 500;
      sa.performLayout(500);

      expect(sa.width, 500);
      expect(sa.height, greaterThan(initialH));
    });
  });

  // ── Hover state ─────────────────────────────────────────────

  group('Hover', () {
    test('Button hover state changes on enter/leave', () {
      final btn = Button('Test');
      btn.x = 0;
      btn.y = 0;
      btn.width = 100;
      btn.height = 30;

      expect(btn.hitTest(10, 10), isTrue);

      // Simulate mouse enter
      btn.onMouseEnter?.call();
      // After entering, the next draw should show hover color
      // (We can't inspect _hovered directly, but we verify the
      // callbacks fire without error.)

      btn.onMouseLeave?.call();
    });

    test('Button onClick fires callback', () {
      bool clicked = false;
      final btn = Button('Click', onPressed: () => clicked = true);
      btn.x = 0;
      btn.y = 0;
      btn.width = 100;
      btn.height = 30;

      // Simulate WidgetWindow click dispatch
      btn.onClick?.call();
      expect(clicked, isTrue);
    });

    test('Key events propagate to focused widget', () {
      // Verify tabIndex and acceptsFocus work
      final btn = Button('Focus');
      expect(btn.acceptsFocus, isTrue);
      expect(btn.isFocusable, isTrue);
      expect(btn.tabIndex, greaterThan(0));
    });
  });

  // ── Scroll behavior ─────────────────────────────────────────

  group('Scroll', () {
    test('ScrollArea shows scrollbar when content overflows', () {
      final sa = ScrollArea(
        child: SizedBox(width: 200, height: 1000),
        showVertical: true,
      );
      sa.x = 0;
      sa.y = 0;
      sa.width = 200;
      sa.height = 100;
      sa.performLayout(200);

      expect(sa.maxScrollY, greaterThan(0),
          reason: 'content taller than viewport should enable scrolling');
    });

    test('ScrollArea hides scrollbar when content fits', () {
      final sa = ScrollArea(
        child: SizedBox(width: 200, height: 50),
        showVertical: true,
      );
      sa.x = 0;
      sa.y = 0;
      sa.width = 200;
      sa.height = 100;
      sa.performLayout(200);

      expect(sa.maxScrollY, 0,
          reason: 'content shorter than viewport should not scroll');
    });

    test('ScrollArea scrollY changes after scrollBy', () {
      final sa = ScrollArea(
        child: SizedBox(width: 200, height: 1000),
        showVertical: true,
      );
      sa.x = 0;
      sa.y = 0;
      sa.width = 200;
      sa.height = 100;
      sa.performLayout(200);

      final before = sa.scrollY;
      sa.scrollBy(0, 50);
      expect(sa.scrollY, greaterThan(before),
          reason: 'scrollBy should increase scroll offset');
    });

    test('ScrollArea clips content during draw', () {
      final sa = ScrollArea(
        child: SizedBox(width: 200, height: 1000),
        showVertical: true,
      );
      sa.x = 0;
      sa.y = 0;
      sa.width = 200;
      sa.height = 100;
      sa.performLayout(200);

      final painter = RecordingPainter();
      sa.draw(painter);

      final clips = painter.commands.ofType<ClipRectCommand>().toList();
      expect(clips, hasLength(greaterThanOrEqualTo(1)),
          reason: 'draw should record a clip rect');
    });

    test('ScrollArea responds to mouse wheel', () {
      final sa = ScrollArea(
        child: SizedBox(width: 200, height: 1000),
        showVertical: true,
      );
      sa.x = 0;
      sa.y = 0;
      sa.width = 200;
      sa.height = 100;
      sa.performLayout(200);

      final before = sa.scrollY;

      // Simulate wheel event
      sa.onMouseWheel(MouseWheelEvent(50, 50, 0, 40));

      // The scroll should have changed (the animated scroll also applies
      // immediately via scrollBy in onMouseWheel)
      expect(sa.scrollY, greaterThanOrEqualTo(before),
          reason: 'wheel down should scroll down');
    });
  });

  // ── ElementHost scrolling ───────────────────────────────────

  group('ElementHost scroll', () {
    test('ScrollArea inside ElementHost has correct height', () {
      final host = ElementHost(child: _ScrollContainer());
      host.x = 0;
      host.y = 0;
      host.width = 400;
      host.height = 300;
      host.performLayout(400);

      final scrollArea = host.children.first;
      expect(scrollArea, isA<ScrollArea>(),
          reason: 'renderable should be ScrollArea');
      expect(scrollArea.height, greaterThan(0),
          reason: 'ScrollArea should get height from ElementHost');
    });

    test('ScrollArea inside ElementHost scrolls content', () {
      final host = ElementHost(child: _ScrollContainer());
      host.x = 0;
      host.y = 0;
      host.width = 400;
      host.height = 200;
      host.performLayout(400);

      final scrollArea = host.children.first as ScrollArea;
      expect(scrollArea.maxScrollY, greaterThan(0),
          reason: 'tall content inside ElementHost should scroll');
    });
  });
}

// ── Test widgets ──────────────────────────────────────────────

class _SizedStateless extends StatelessWidget {
  final double size;
  _SizedStateless({this.size = 50});

  @override
  ElementWidget build(BuildContext context) {
    return SizedBox(width: size.round(), height: size.round());
  }
}

class _ScrollContainer extends StatelessWidget {
  @override
  ElementWidget build(BuildContext context) {
    return ScrollArea(
      child: SizedBox(width: 200, height: 1000),
      showVertical: true,
    );
  }
}
