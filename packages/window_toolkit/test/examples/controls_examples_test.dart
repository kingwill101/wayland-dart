// ignore_for_file: avoid_relative_lib_imports

import 'package:test/test.dart';
import 'package:window_toolkit/window_toolkit.dart' as wt;

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
      ..withBounds(width: 640, height: 360);

    expect(harness.draw, returnsNormally);
    expect(harness.painter.commands, isNotEmpty);

    final center = harness.root as wt.Center;
    final cardBox = center.child as wt.SizedBox;
    expect(cardBox.width, 420);
    expect(cardBox.height, 190);
    final card = cardBox.child as wt.Card;
    final row = card.children.first as wt.HBox;
    expect(row.children.first.width, 18);
    expect(row.children.first.height, 18);
  });
}
