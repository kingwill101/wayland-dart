// ignore_for_file: avoid_relative_lib_imports

import 'package:test/test.dart';

import '../../example/lib/controls_examples.dart';
import '../support/widget_test_harness.dart';

void main() {
  test('Checkbox example draws without errors', () {
    final harness = WidgetHarness(buildCheckboxExample())
      ..withBounds(width: 360, height: 220);

    expect(harness.draw, returnsNormally);
    expect(harness.painter.commands, isNotEmpty);
  });

  test('Slider example draws without errors', () {
    final harness = WidgetHarness(buildSliderExample())
      ..withBounds(width: 360, height: 220);

    expect(harness.draw, returnsNormally);
    expect(harness.painter.commands, isNotEmpty);
  });

  test('Card example draws without errors', () {
    final harness = WidgetHarness(buildCardExample())
      ..withBounds(width: 360, height: 220);

    expect(harness.draw, returnsNormally);
    expect(harness.painter.commands, isNotEmpty);
  });
}
