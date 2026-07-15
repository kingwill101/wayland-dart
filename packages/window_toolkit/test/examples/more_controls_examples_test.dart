// ignore_for_file: avoid_relative_lib_imports

import 'package:test/test.dart';

import '../../example/lib/more_controls_examples.dart';
import '../support/widget_test_harness.dart';

void main() {
  test('Switch example draws without errors', () {
    final harness = WidgetHarness(buildSwitchExample())
      ..withBounds(width: 360, height: 240);

    expect(harness.draw, returnsNormally);
    expect(harness.painter.commands, isNotEmpty);
  });

  test('Radio example draws without errors', () {
    final harness = WidgetHarness(buildRadioExample())
      ..withBounds(width: 360, height: 240);

    expect(harness.draw, returnsNormally);
    expect(harness.painter.commands, isNotEmpty);
  });

  test('Icon button example draws without errors', () {
    final harness = WidgetHarness(buildIconButtonExample())
      ..withBounds(width: 360, height: 240);

    expect(harness.draw, returnsNormally);
    expect(harness.painter.commands, isNotEmpty);
  });
}
