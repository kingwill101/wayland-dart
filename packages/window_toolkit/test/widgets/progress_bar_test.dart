import 'package:test/test.dart';
import 'package:window_toolkit/window_toolkit.dart';

import '../support/widget_test_harness.dart';

void main() {
  test('ProgressBar draws the fill and percentage text', () {
    final bar = ProgressBar(value: 50, barWidth: 200, barHeight: 20);
    bar.x = 4;
    bar.y = 6;

    final painter = RecordingPainter();
    bar.draw(painter);

    final rects = painter.commands.ofType<DrawRectCommand>().toList();
    final text = painter.commands.singleOfType<DrawTextCommand>();

    expect(rects, hasLength(2));
    expect(rects[0].rect.left, 4);
    expect(rects[0].rect.top, 6);
    expect(rects[0].rect.right, 204);
    expect(rects[0].rect.bottom, 26);
    expect(rects[0].paint.color, bar.backgroundColor);
    expect(rects[1].rect.left, 4);
    expect(rects[1].rect.top, 6);
    expect(rects[1].rect.right, 104);
    expect(rects[1].rect.bottom, 26);
    expect(rects[1].paint.color, bar.fillColor);
    expect(text.text, '50%');
    expect(text.position.dx, 92);
    expect(text.position.dy, 8);
  });
}
