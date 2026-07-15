// ignore_for_file: avoid_relative_lib_imports

import 'package:test/test.dart';

import '../../example/lib/layout_examples.dart';
import '../support/widget_test_harness.dart';

void main() {
  test('Wrap example draws without errors', () {
    final harness = WidgetHarness(buildWrapExample())
      ..withBounds(width: 360, height: 240);

    expect(harness.draw, returnsNormally);
    expect(harness.painter.commands, isNotEmpty);
  });
}
