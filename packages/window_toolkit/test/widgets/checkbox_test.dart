import 'package:test/test.dart';
import 'package:window_toolkit/window_toolkit.dart';

import '../support/widget_test_harness.dart';

void main() {
  test('Checkbox toggles state and draws a checkmark when checked', () {
    var changedCalls = 0;
    final checkbox = Checkbox(checked: false, onChanged: () => changedCalls++);
    checkbox.x = 10;
    checkbox.y = 12;
    checkbox.width = 18;
    checkbox.height = 18;

    final painter = RecordingPainter();
    checkbox.draw(painter);

    expect(painter.commands.ofType<DrawRectCommand>(), hasLength(5));
    expect(painter.commands.ofType<DrawLineCommand>(), isEmpty);

    checkbox.toggle();
    expect(checkbox.checked, isTrue);
    expect(changedCalls, 1);

    painter.clearCommands();
    checkbox.draw(painter);

    expect(painter.commands.ofType<DrawRectCommand>(), hasLength(5));
    expect(painter.commands.ofType<DrawLineCommand>(), hasLength(2));
  });
}
