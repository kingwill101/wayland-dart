import 'package:test/test.dart';
import 'package:window_toolkit/window_toolkit.dart';

import '../support/widget_test_harness.dart';

void main() {
  test('Label measures and draws text', () {
    final label = Label('hello', fontSize: 12);
    final harness = WidgetHarness(label)..withBounds(width: 200, height: 40);
    label.measure(harness.painter);
    expect(harness.draw, returnsNormally);
    expect(label.width, greaterThan(0));
    expect(harness.painter.commands.whereType<DrawTextCommand>(), isNotEmpty);
  });

  test('SizedBox forces dimensions', () {
    final box = SizedBox(width: 50, height: 20, child: Label('x'));
    final harness = WidgetHarness(box)..withBounds(width: 200, height: 40);
    box.measure(harness.painter);
    expect(box.width, 50);
    expect(box.height, 20);
    expect(harness.draw, returnsNormally);
  });

  test('VBox stacks children vertically', () {
    final a = Label('a');
    final b = Label('b');
    final box = VBox(spacing: 4, children: [a, b]);
    final harness = WidgetHarness(box)..withBounds(width: 100, height: 100);
    box.measure(harness.painter);
    expect(box.height, greaterThan(a.height));
    expect(harness.draw, returnsNormally);
  });

  test('DecoratedBox draws background', () {
    final box = DecoratedBox(
      color: const Color(40, 40, 40),
      borderRadius: 6,
      padding: 4,
      child: Label('chip'),
    );
    final harness = WidgetHarness(box)..withBounds(width: 100, height: 40);
    box.measure(harness.painter);
    expect(harness.draw, returnsNormally);
    expect(harness.painter.commands.whereType<DrawRectCommand>(), isNotEmpty);
  });

  test('Chip measures label and draws rounded body', () {
    final chip = Chip(label: '1', selected: true);
    final harness = WidgetHarness(chip)..withBounds(width: 80, height: 30);
    chip.measure(harness.painter);
    expect(chip.width, greaterThan(10));
    expect(harness.draw, returnsNormally);
    expect(harness.painter.commands.whereType<DrawRectCommand>(), isNotEmpty);
  });

  test('Stack positions child with Positioned', () {
    final stack = Stack(
      children: [
        Label('bg'),
        Positioned(left: 10, top: 5, child: Label('fg')),
      ],
    );
    final harness = WidgetHarness(stack)..withBounds(width: 100, height: 50);
    stack.measure(harness.painter);
    expect(harness.draw, returnsNormally);
    final positioned = stack.children.whereType<Positioned>().first;
    expect(positioned.left, 10);
    expect(positioned.top, 5);
  });

  test('Center places child in the middle', () {
    final child = SizedBox(width: 20, height: 10, child: Label('c'));
    final center = Center(child: child);
    center.width = 100;
    center.height = 40;
    final harness = WidgetHarness(center)..withBounds(width: 100, height: 40);
    child.measure(harness.painter);
    expect(harness.draw, returnsNormally);
    expect(child.x, greaterThan(center.x));
  });

  test('MouseRegion tracks hover callbacks', () {
    var entered = false;
    var exited = false;
    final region = MouseRegion(
      child: SizedBox(width: 40, height: 20),
      onEnter: () => entered = true,
      onExit: () => exited = true,
    );
    region.width = 40;
    region.height = 20;
    region.onMouseEnter?.call();
    expect(entered, isTrue);
    expect(region.isHovered, isTrue);
    region.onMouseLeave?.call();
    expect(exited, isTrue);
    expect(region.isHovered, isFalse);
  });

  test('ThemeMetrics presets differ', () {
    expect(
      ThemeMetrics.compact.spacingMd,
      lessThan(ThemeMetrics.comfortable.spacingMd),
    );
  });
}
