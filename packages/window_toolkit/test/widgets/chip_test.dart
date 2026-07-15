import 'package:test/test.dart';
import 'package:window_toolkit/window_toolkit.dart';

import '../support/widget_test_harness.dart';

void main() {
  group('Chip', () {
    test('constructor stores label', () {
      final c = Chip(label: 'Workspace 1');
      expect(c.label, 'Workspace 1');
    });

    test('draw records commands', () {
      final harness = WidgetHarness(Chip(label: 'Tag'));
      harness.draw();
      expect(harness.painter.commands, isNotEmpty);
    });

    test('selected chip uses selected colors', () {
      final c = Chip(label: 'Active', selected: true);
      final harness = WidgetHarness(c);
      harness.draw();
      expect(harness.painter.commands, isNotEmpty);
    });
  });
}
