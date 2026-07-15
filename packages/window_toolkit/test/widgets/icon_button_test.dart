import 'package:test/test.dart';
import 'package:window_toolkit/window_toolkit.dart';

import '../support/widget_test_harness.dart';

void main() {
  group('IconButton', () {
    test('shape is stored', () {
      final ib = IconButton(IconShape.circle);
      expect(ib.shape, IconShape.circle);
    });

    test('onPressed fires via onClick', () {
      int count = 0;
      final ib = IconButton(IconShape.square, onPressed: () => count++);
      ib.onClick?.call();
      expect(count, 1);
    });

    test('draw records commands', () {
      final harness = WidgetHarness(IconButton(IconShape.square));
      harness.draw();
      expect(harness.painter.commands, isNotEmpty);
    });
  });
}
