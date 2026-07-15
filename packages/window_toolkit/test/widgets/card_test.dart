import 'package:test/test.dart';
import 'package:window_toolkit/window_toolkit.dart';

import '../support/widget_test_harness.dart';

void main() {
  test('Card draws container chrome and lays out children', () {
    final childA = Label('A');
    final childB = Label('B');
    final card = Card(
      title: 'Settings',
      children: [childA, childB],
    );
    card.x = 4;
    card.y = 6;
    card.width = 220;
    card.height = 120;

    final painter = RecordingPainter();
    card.draw(painter);

    final rects = painter.commands.ofType<DrawRectCommand>().toList();
    final texts = painter.commands.ofType<DrawTextCommand>().toList();

    expect(rects.length, greaterThanOrEqualTo(5));
    expect(texts, isNotEmpty);
    expect(texts.first.text, 'Settings');
    expect(childA.x, 16);
    expect(childA.y, 40);
    expect(childB.y, greaterThan(childA.y));
    expect(card.hitTest(20, 44), isTrue);
    expect(card.hitTest(5, 7), isFalse);
  });
}
