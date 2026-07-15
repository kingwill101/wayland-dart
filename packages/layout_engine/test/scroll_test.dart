import 'package:test/test.dart';
import 'package:layout_engine/layout_engine.dart';

void main() {
  group('ScrollController', () {
    test('ViewportScrollController starts at 0', () {
      final ctrl = ViewportScrollController();
      expect(ctrl.offset, 0);
      expect(ctrl.scrollPercent, 0);
    });

    test('jumpTo clamps to valid range', () {
      final ctrl = ViewportScrollController();
      ctrl.updateMetrics(viewportExtent: 100, contentExtent: 500);
      expect(ctrl.maxOffset, 400);

      ctrl.jumpTo(200);
      expect(ctrl.offset, 200);

      ctrl.jumpTo(999);
      expect(ctrl.offset, 400); // clamped

      ctrl.jumpTo(-10);
      expect(ctrl.offset, 0); // clamped
    });

    test('scrollBy changes offset', () {
      final ctrl = ViewportScrollController();
      ctrl.updateMetrics(viewportExtent: 100, contentExtent: 300);
      expect(ctrl.maxOffset, 200);

      ctrl.scrollBy(50);
      expect(ctrl.offset, 50);

      ctrl.scrollBy(-20);
      expect(ctrl.offset, 30);
    });

    test('listeners fire on change', () {
      final ctrl = ViewportScrollController();
      ctrl.updateMetrics(viewportExtent: 50, contentExtent: 200);

      int callCount = 0;
      ctrl.addListener(() => callCount++);

      ctrl.jumpTo(50);
      expect(callCount, 1);

      ctrl.jumpTo(50); // no change
      expect(callCount, 1); // no callback

      ctrl.scrollBy(10);
      expect(callCount, 2);
    });

    test('scrollPercent reflects position', () {
      final ctrl = ViewportScrollController();
      ctrl.updateMetrics(viewportExtent: 50, contentExtent: 150);
      expect(ctrl.maxOffset, 100);

      expect(ctrl.scrollPercent, 0);
      ctrl.jumpTo(50);
      expect(ctrl.scrollPercent, closeTo(0.5, 0.01));
      ctrl.jumpTo(100);
      expect(ctrl.scrollPercent, closeTo(1.0, 0.01));
    });
  });

  group('RenderViewport', () {
    test('lays out child with unbounded scroll extent', () {
      final child = RenderDelegateBox((r, c) {
        r.size = Size(200, 1000); // tall content
      });
      final vp = RenderViewport(scrollDirection: Axis.vertical);
      vp.attach(child);

      vp.layout(BoxConstraints(maxWidth: 200, maxHeight: 300));
      expect(vp.size.width, 200);
      expect(vp.size.height, 300);
      // Child should have its full height
      expect(child.size.width, 200);
      expect(child.size.height, 1000);
    });

    test('applies scroll offset to child position', () {
      final child = RenderDelegateBox((r, c) {
        r.size = Size(200, 1000);
      });
      final ctrl = ViewportScrollController();
      ctrl.updateMetrics(viewportExtent: 300, contentExtent: 1000);
      ctrl.jumpTo(100);

      final vp = RenderViewport(controller: ctrl, scrollDirection: Axis.vertical);
      vp.attach(child);

      vp.layout(BoxConstraints(maxWidth: 200, maxHeight: 300));
      expect(child.offset.dy, -100.0);
    });

    test('horizontal scroll direction', () {
      final child = RenderDelegateBox((r, c) {
        r.size = Size(1000, 200);
      });
      final ctrl = ViewportScrollController();
      ctrl.updateMetrics(viewportExtent: 300, contentExtent: 1000);
      ctrl.jumpTo(200);

      final vp = RenderViewport(controller: ctrl, scrollDirection: Axis.horizontal);
      vp.attach(child);

      vp.layout(BoxConstraints(maxWidth: 300, maxHeight: 200));
      expect(vp.size.width, 300);
      expect(child.offset.dx, -200.0);
    });
  });
}
