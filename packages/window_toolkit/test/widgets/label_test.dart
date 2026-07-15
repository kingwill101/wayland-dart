import 'package:test/test.dart';
import 'package:window_toolkit/window_toolkit.dart';

import '../support/widget_test_harness.dart';

void main() {
  group('Label', () {
    test('constructor asserts positive fontSize', () {
      expect(() => Label('x', fontSize: 0), throwsA(isA<AssertionError>()));
      expect(() => Label('x', fontSize: -1), throwsA(isA<AssertionError>()));
    });

    test('constructor stores text', () {
      final lbl = Label('Hello');
      expect(lbl.text, 'Hello');
    });

    test('default fontSize from theme', () {
      final lbl = Label('Test');
      expect(lbl.fontSize, greaterThan(0));
    });

    test('draw records text command', () {
      final harness = WidgetHarness(Label('Hello World', fontSize: 14));
      harness.draw();
      final texts = harness.painter.commands.ofType<DrawTextCommand>();
      expect(texts, hasLength(1));
      expect(texts.first.text, 'Hello World');
      expect(texts.first.size, 14);
    });

    test('measure returns advance width', () {
      final lbl = Label('Measure', fontSize: 14);
      final painter = RecordingPainter();
      lbl.measure(painter);
      expect(lbl.width, greaterThan(0));
    });

    test('color is applied when set', () {
      final lbl = Label('Red', fontSize: 12, color: const Color(255, 0, 0));
      final harness = WidgetHarness(lbl);
      harness.draw();
      final cmd = harness.painter.commands.singleOfType<DrawTextCommand>();
      expect(cmd.color?.r, 255);
      expect(cmd.color?.g, 0);
      expect(cmd.color?.b, 0);
    });

    test('hitTest succeeds within bounds', () {
      final lbl = Label('Hit', fontSize: 14);
      lbl.x = 5;
      lbl.y = 5;
      // Label has default width from constructor
      expect(lbl.hitTest(6, 6), isTrue);
      expect(lbl.hitTest(0, 0), isFalse);
    });
  });
}
