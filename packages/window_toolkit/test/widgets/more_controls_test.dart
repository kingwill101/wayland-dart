import 'package:test/test.dart';
import 'package:window_toolkit/window_toolkit.dart';


void main() {
  test('Switch toggles and changes its thumb position', () {
    var calls = 0;
    final sw = Switch(onChanged: () => calls++);
    sw.x = 10;
    sw.y = 12;

    final painter = RecordingPainter();
    sw.draw(painter);

    expect(painter.commands.ofType<DrawRectCommand>(), hasLength(3));
    expect(painter.commands.ofType<DrawCircleCommand>(), hasLength(1));
    expect(sw.value, isFalse);

    sw.toggle();
    expect(sw.value, isTrue);
    expect(calls, 1);

    painter.clearCommands();
    sw.draw(painter);
    final circle = painter.commands.singleOfType<DrawCircleCommand>();
    expect(circle.center.dx, closeTo(41, 0.001));
  });

  test('RadioButton selects and draws a filled center', () {
    var calls = 0;
    final radio = RadioButton('Choice', onChanged: () => calls++);
    radio.x = 6;
    radio.y = 8;

    final painter = RecordingPainter();
    radio.draw(painter);

    expect(painter.commands.ofType<DrawCircleCommand>(), hasLength(2));
    expect(radio.selected, isFalse);

    radio.select();
    expect(radio.selected, isTrue);
    expect(calls, 1);

    painter.clearCommands();
    radio.draw(painter);
    expect(painter.commands.ofType<DrawCircleCommand>(), hasLength(3));
  });

  test('IconButton reacts to hover and presses', () {
    var presses = 0;
    final button = IconButton(IconShape.triangle, onPressed: () => presses++);
    button.x = 4;
    button.y = 5;

    final painter = RecordingPainter();
    button.draw(painter);
    final idleFill = painter.commands.ofType<DrawRectCommand>().first;
    expect(idleFill.paint.color, button.backgroundColor);

    button.onMouseEnter?.call();
    painter.clearCommands();
    button.draw(painter);
    final hoverFill = painter.commands.ofType<DrawRectCommand>().first;
    expect(hoverFill.paint.color, button.hoverColor);

    button.press();
    expect(presses, 1);
  });
}
