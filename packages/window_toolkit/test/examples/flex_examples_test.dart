// ignore_for_file: avoid_relative_lib_imports

import 'package:test/test.dart';

import '../../example/lib/flex_examples.dart';
import '../support/widget_test_harness.dart';

void main() {
  test('Row example draws without errors', () {
    final harness = WidgetHarness(buildRowExample())
      ..withBounds(width: 360, height: 220);

    expect(harness.draw, returnsNormally);
    expect(harness.painter.commands, isNotEmpty);
  });

  test('Column example draws without errors', () {
    final harness = WidgetHarness(buildColumnExample())
      ..withBounds(width: 360, height: 220);

    expect(harness.draw, returnsNormally);
    expect(harness.painter.commands, isNotEmpty);
  });

  test('Flex example draws without errors', () {
    final harness = WidgetHarness(buildFlexExample())
      ..withBounds(width: 360, height: 220);

    expect(harness.draw, returnsNormally);
    expect(harness.painter.commands, isNotEmpty);
  });
}
