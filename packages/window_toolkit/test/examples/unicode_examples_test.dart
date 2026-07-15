// ignore_for_file: avoid_relative_lib_imports

import 'package:test/test.dart';

import '../../example/lib/unicode_examples.dart';
import '../support/widget_test_harness.dart';

void main() {
  test('Unicode example draws without errors', () {
    final harness = WidgetHarness(buildUnicodeExample())
      ..withBounds(width: 640, height: 360);

    expect(harness.draw, returnsNormally);
    expect(harness.painter.commands, isNotEmpty);
  });
}
