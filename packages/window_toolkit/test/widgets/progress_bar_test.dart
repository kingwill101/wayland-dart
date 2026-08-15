import 'package:test/test.dart';
import 'package:window_toolkit/window_toolkit.dart';

import '../support/widget_test_harness.dart';

void main() {
  group('ProgressBar', () {
    test('constructor asserts barWidth > 0', () {
      expect(() => ProgressBar(barWidth: 0), throwsA(isA<AssertionError>()));
    });

    test('constructor asserts barHeight > 0', () {
      expect(
        () => ProgressBar(barWidth: 100, barHeight: 0),
        throwsA(isA<AssertionError>()),
      );
    });

    test('constructor asserts max > min', () {
      expect(
        () => ProgressBar(barWidth: 100, min: 50, max: 25),
        throwsA(isA<AssertionError>()),
      );
    });

    test('default values', () {
      final pb = ProgressBar(barWidth: 200);
      expect(pb.value, 0);
      expect(pb.min, 0);
      expect(pb.max, 100);
    });

    test('barHeight sets height, width from performLayout', () {
      final pb = ProgressBar(barWidth: 200, barHeight: 20);
      pb.performLayout(400);
      // width is the container width after performLayout.
      expect(pb.width, 400);
      expect(pb.height, 20);
    });

    test('draw records rect and text commands', () {
      final harness = WidgetHarness(ProgressBar(barWidth: 200, value: 50));
      harness.draw();
      final rects = harness.painter.commands.ofType<DrawRectCommand>();
      expect(rects.length, greaterThanOrEqualTo(2));
    });
  });
}
