import 'package:test/test.dart';
import 'package:window_toolkit/window_toolkit.dart';

import '../support/widget_test_harness.dart';

void main() {
  test('Slider clamps values and draws track fill and thumb', () {
    var changedCalls = 0;
    final slider = Slider(
      min: 0,
      max: 100,
      value: 25,
      onChanged: () => changedCalls++,
    );
    slider.x = 8;
    slider.y = 10;
    slider.width = 200;
    slider.height = 20;

    final painter = RecordingPainter();
    slider.draw(painter);

    final rects = painter.commands.ofType<DrawRectCommand>().toList();
    final circles = painter.commands.ofType<DrawCircleCommand>().toList();
    final text = painter.commands.singleOfType<DrawTextCommand>();

    expect(rects, hasLength(2));
    expect(circles, hasLength(1));
    expect(text.text, '25');
    expect(rects[0].rect.left, 8);
    expect(rects[0].rect.top, 18);
    expect(rects[0].rect.right, 208);
    expect(rects[1].rect.right, 58);
    expect(circles.single.center.dx, 58);

    slider.setValue(175);
    expect(slider.value, 100);
    expect(changedCalls, 1);

    slider.setFraction(-1);
    expect(slider.value, 0);
    expect(changedCalls, 2);
  });
}
