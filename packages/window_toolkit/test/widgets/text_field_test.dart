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
      final tf = TextField()
        ..controller.text = 'Hello';
      expect(tf.controller.text, 'Hello');
    });

    test('backspace removes last character', () {
      final tf = TextField()..controller.text = 'Hi';
      final mods = ModifierState(modsDepressed: 0, modsLatched: 0, modsLocked: 0, group: 0);
      tf.onKeyPressed(KeyEvent(42, true, mods));
      expect(tf.controller.text, 'H');
    });

    test('clear empties text', () {
      final tf = TextField()
        ..controller.text = 'Text';
      tf.controller.text = '';
      expect(tf.controller.text, isEmpty);
    });

    test('draw records commands', () {
      final harness = WidgetHarness(TextField());
      harness.draw();
      expect(harness.painter.commands, isNotEmpty);
    });
  });
}
