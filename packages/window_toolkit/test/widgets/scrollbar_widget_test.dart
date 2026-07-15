import 'package:layout_engine/layout_engine.dart' show ViewportScrollController;
import 'package:test/test.dart';
import 'package:window_toolkit/window_toolkit.dart';

void main() {
  group('Scrollbar', () {
    test('hidden when content fits viewport', () {
      final ctrl = ViewportScrollController();
      ctrl.updateMetrics(viewportExtent: 200, contentExtent: 100);
      final sb = Scrollbar(controller: ctrl, viewportHeight: 200);
      expect(sb.hitTest(0, 0), isFalse);
    });

    test('visible when content overflows', () {
      final ctrl = ViewportScrollController();
      ctrl.updateMetrics(viewportExtent: 100, contentExtent: 500);
      final sb = Scrollbar(controller: ctrl, viewportHeight: 100);
      sb.x = 0;
      sb.y = 0;
      sb.width = 10;
      expect(sb.hitTest(5, 50), isTrue);
    });

    test('draw records commands', () {
      final ctrl = ViewportScrollController();
      ctrl.updateMetrics(viewportExtent: 100, contentExtent: 500);
      ctrl.jumpTo(100);
      final sb = Scrollbar(controller: ctrl, viewportHeight: 100);
      sb.x = 0;
      sb.y = 0;
      sb.width = 10;

      final painter = RecordingPainter();
      sb.draw(painter);

      final rects = painter.commands.ofType<DrawRectCommand>().toList();
      expect(rects.length, greaterThanOrEqualTo(2)); // track + thumb
    });

    test('scrollWheel scrolls controller', () {
      final ctrl = ViewportScrollController();
      ctrl.updateMetrics(viewportExtent: 100, contentExtent: 500);
      final sb = Scrollbar(controller: ctrl, viewportHeight: 100);

      sb.onMouseWheel(MouseWheelEvent(0, 0, 0, 40));
    });
  });
}
