// ignore_for_file: avoid_relative_lib_imports

import 'package:test/test.dart';

import '../../example/lib/popup_examples.dart';
import '../support/widget_test_harness.dart';

void main() {
  test('Context menu content draws without errors', () {
    final harness = WidgetHarness(buildContextMenuContent())
      ..withBounds(width: 200, height: 160);
    expect(harness.draw, returnsNormally);
    expect(harness.painter.commands, isNotEmpty);
  });

  test('Dropdown content draws without errors', () {
    final harness = WidgetHarness(buildDropdownContent())
      ..withBounds(width: 200, height: 160);
    expect(harness.draw, returnsNormally);
    expect(harness.painter.commands, isNotEmpty);
  });
}
