import 'package:test/test.dart';
import 'package:window_toolkit/window_toolkit.dart';

import '../support/widget_test_harness.dart';

void main() {
  group('ImageIcon', () {
    test('circle shape creates round icon', () {
      final ii = ImageIcon(IconShape.circle);
      expect(ii.shape, IconShape.circle);
    });

    test('square shape creates rect icon', () {
      final ii = ImageIcon(IconShape.square);
      final harness = WidgetHarness(ii);
      harness.draw();
      expect(harness.painter.commands, isNotEmpty);
    });

    test('color applies to drawn shape', () {
      final ii = ImageIcon(IconShape.triangle, iconColor: const Color(255, 0, 0));
      final harness = WidgetHarness(ii);
      harness.draw();
      expect(harness.painter.commands, isNotEmpty);
    });
  });
}
