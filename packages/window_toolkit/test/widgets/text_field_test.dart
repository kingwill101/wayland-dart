import 'package:test/test.dart';
import 'package:window_toolkit/window_toolkit.dart';

import '../support/widget_test_harness.dart';

void main() {
  group('TextField', () {
    test('default text is empty', () {
      final tf = TextField();
      expect(tf.controller.text, isEmpty);
    });

    test('controller.text updates displayed text', () {
      final tf = TextField()..controller.text = 'Hello';
      expect(tf.controller.text, 'Hello');
    });

    test('backspace removes last character', () {
      final tf = TextField()..controller.text = 'Hi';
      final mods = ModifierState(
        modsDepressed: 0,
        modsLatched: 0,
        modsLocked: 0,
        group: 0,
      );
      tf.onKeyPressed(KeyEvent(42, true, mods));
      expect(tf.controller.text, 'H');
    });

    test('clear empties text', () {
      final tf = TextField()..controller.text = 'Text';
      tf.controller.text = '';
      expect(tf.controller.text, isEmpty);
    });

    test('draw records commands', () {
      final harness = WidgetHarness(TextField());
      harness.draw();
      expect(harness.painter.commands, isNotEmpty);
    });
    test('draws cursor at correct position', () {
      final ctrl = TextEditingController(text: 'hello');
      ctrl.cursor = 3;
      final tf = TextField(controller: ctrl);
      tf.x = 10;
      tf.y = 10;
      tf.width = 120;
      tf.height = 24;
      tf.onClick?.call(); // gain focus

      final painter = RecordingPainter();
      tf.draw(painter);

      final lines = painter.commands.ofType<DrawLineCommand>().toList();
      expect(lines, hasLength(1));
      expect(lines.single.from.dx, 38);
    });

    test('insert, delete, and cursor navigation work', () {
      final ctrl = TextEditingController(text: 'hi');
      ctrl.cursor = 2;
      ctrl.insert('!');
      expect(ctrl.text, 'hi!');
      expect(ctrl.cursor, 3);

      ctrl.moveCursorLeft();
      expect(ctrl.cursor, 2);

      ctrl.deleteLeft();
      expect(ctrl.text, 'h!');
      expect(ctrl.cursor, 1);
    });
  });
}
