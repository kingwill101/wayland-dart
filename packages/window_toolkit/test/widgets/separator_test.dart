import 'package:test/test.dart';
import 'package:window_toolkit/window_toolkit.dart';

import '../support/widget_test_harness.dart';

void main() {
  group('Separator', () {
    test('sets width from lineWidth + margin', () {
      final sep = Separator(lineWidth: 2, margin: 4);
      expect(sep.width, 10);
    });

    test('draw records commands', () {
      final harness = WidgetHarness(Separator());
      harness.draw();
      expect(harness.painter.commands, isNotEmpty);
    });
  });
}
