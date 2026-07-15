// ignore_for_file: avoid_relative_lib_imports

import 'package:test/test.dart';

import '../../example/lib/compound_examples.dart';
import '../support/widget_test_harness.dart';

void main() {
  test('ScrollArea example draws without errors', () {
    final harness = WidgetHarness(buildScrollAreaExample())
      ..withBounds(width: 400, height: 300);
    expect(harness.draw, returnsNormally);
    expect(harness.painter.commands, isNotEmpty);
  });

  test('TextField example draws without errors', () {
    final harness = WidgetHarness(buildTextFieldExample())
      ..withBounds(width: 300, height: 200);
    expect(harness.draw, returnsNormally);
    expect(harness.painter.commands, isNotEmpty);
  });

  test('Dropdown example draws without errors', () {
    final harness = WidgetHarness(buildDropdownExample())
      ..withBounds(width: 200, height: 100);
    expect(harness.draw, returnsNormally);
    expect(harness.painter.commands, isNotEmpty);
  });

  test('ListBox example draws without errors', () {
    final harness = WidgetHarness(buildListBoxExample())
      ..withBounds(width: 200, height: 200);
    expect(harness.draw, returnsNormally);
    expect(harness.painter.commands, isNotEmpty);
  });

  test('Menu example draws without errors', () {
    final harness = WidgetHarness(buildMenuExample())
      ..withBounds(width: 200, height: 200);
    expect(harness.draw, returnsNormally);
    expect(harness.painter.commands, isNotEmpty);
  });

  test('Dialog example draws without errors', () {
    final harness = WidgetHarness(buildDialogExample())
      ..withBounds(width: 360, height: 240);
    expect(harness.draw, returnsNormally);
    expect(harness.painter.commands, isNotEmpty);
  });

  test('Tab example draws without errors', () {
    final harness = WidgetHarness(buildTabExample())
      ..withBounds(width: 400, height: 120);
    expect(harness.draw, returnsNormally);
    expect(harness.painter.commands, isNotEmpty);
  });

  test('Tooltip example draws without errors', () {
    final harness = WidgetHarness(buildTooltipExample())
      ..withBounds(width: 200, height: 100);
    expect(harness.draw, returnsNormally);
    expect(harness.painter.commands, isNotEmpty);
  });
}
