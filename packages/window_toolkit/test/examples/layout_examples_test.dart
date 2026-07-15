// ignore_for_file: avoid_relative_lib_imports

import 'package:test/test.dart';

import '../../example/lib/layout_examples.dart';
import '../support/widget_test_harness.dart';

void main() {
  test('HBox example draws without errors', () {
    final harness = WidgetHarness(buildHBoxExample())
      ..withBounds(width: 320, height: 180);

    expect(harness.draw, returnsNormally);
    expect(harness.painter.commands, isNotEmpty);
  });

  test('Align example draws without errors', () {
    final harness = WidgetHarness(buildAlignExample())
      ..withBounds(width: 320, height: 180);

    expect(harness.draw, returnsNormally);
    expect(harness.painter.commands, isNotEmpty);
  });

  test('Padding example draws without errors', () {
    final harness = WidgetHarness(buildPaddingExample())
      ..withBounds(width: 320, height: 180);

    expect(harness.draw, returnsNormally);
    expect(harness.painter.commands, isNotEmpty);
  });
}
