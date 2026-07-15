import 'package:test/test.dart';
import 'package:window_toolkit/window_toolkit.dart';

import '../support/widget_test_harness.dart';

void main() {
  group('Frame', () {
    test('empty frame has no children', () {
      final f = Frame();
      expect(f.children, isEmpty);
    });

    test('constructor asserts borderWidth >= 0', () {
      expect(() => Frame(borderWidth: -1), throwsA(isA<AssertionError>()));
    });

    test('lays out children', () {
      final f = Frame(children: [Button('A'), Button('B')]);
      f.performLayout(400);
      expect(f.children.length, 2);
    });

    test('draw records commands', () {
      final harness = WidgetHarness(Frame(children: [Button('OK')]));
      harness.draw();
      expect(harness.painter.commands, isNotEmpty);
    });
  });
}
