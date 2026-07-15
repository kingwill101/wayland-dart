import 'package:test/test.dart';
import 'package:window_toolkit/window_toolkit.dart';

import '../support/widget_test_harness.dart';

void main() {
  test('Button records idle and hover draws', () {
    final button = Button('OK');
    button.x = 12;
    button.y = 8;

    final painter = RecordingPainter();

    button.draw(painter);

    final idleRect = painter.commands.singleOfType<DrawRectCommand>();
    final idleText = painter.commands.singleOfType<DrawTextCommand>();

    expect(idleRect.rect.left, 12);
    expect(idleRect.rect.top, 8);
    expect(idleRect.rect.right, 36);
    expect(idleRect.rect.bottom, 32);
    expect(idleRect.paint.color, button.backgroundColor);
    expect(idleText.text, 'OK');
    expect(idleText.position.dx, 16);
    expect(idleText.position.dy, 12);

    button.onMouseEnter?.call();
    painter.clearCommands();
    button.draw(painter);

    final hoverRect = painter.commands.singleOfType<DrawRectCommand>();
    expect(hoverRect.paint.color, button.hoverColor);

    button.onMouseLeave?.call();
    painter.clearCommands();
    button.draw(painter);

    final restoredRect = painter.commands.singleOfType<DrawRectCommand>();
    expect(restoredRect.paint.color, button.backgroundColor);
  });
}
