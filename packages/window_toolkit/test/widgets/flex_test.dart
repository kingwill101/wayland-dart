import 'package:test/test.dart';
import 'package:window_toolkit/window_toolkit.dart';

import '../support/widget_test_harness.dart';

void main() {
  test('Row lays out fixed and expanded children', () {
    final left = Button('A');
    final middle = Expanded(child: Button('Stretch'));
    final right = Button('B');

    final row = Row(
      spacing: 8,
      children: [left, middle, right],
    );
    row.x = 10;
    row.y = 20;
    row.width = 240;
    row.height = 48;

    final painter = RecordingPainter();
    row.draw(painter);

    expect(left.x, 10);
    expect(middle.x, 34);
    expect(right.x, 234);
    expect(middle.width, 192);
    expect(middle.height, 24);
    expect(row.hitTest(12, 22), isTrue);
    expect(row.hitTest(220, 22), isTrue);
  });

  test('Column stretches cross axis and keeps flexible children bounded', () {
    final top = Button('Top');
    final middle = Flexible(child: Label('Loose'), fit: FlexFit.loose);
    final bottom = Expanded(child: Button('Bottom'));

    final column = Column(
      spacing: 6,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [top, middle, bottom],
    );
    column.x = 4;
    column.y = 6;
    column.width = 180;
    column.height = 220;

    final painter = RecordingPainter();
    column.draw(painter);

    expect(top.width, 180);
    expect(middle.width, 180);
    expect(bottom.width, 180);
    expect(bottom.height, greaterThan(0));
    expect(column.hitTest(10, 12), isTrue);
    expect(column.hitTest(2, 2), isFalse);
  });

  test('Flex main axis spacing modes work', () {
    final flex = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [Button('A'), Button('B'), Button('C')],
    );
    flex.x = 0;
    flex.y = 0;
    flex.width = 200;
    flex.height = 40;

    flex.layout(flex.width, flex.height);

    expect(flex.children[0].x, 0);
    expect(flex.children[1].x, greaterThan(flex.children[0].x));
    expect(flex.children[2].x, greaterThan(flex.children[1].x));
  });
}
