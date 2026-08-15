import 'package:test/test.dart';
import 'package:window_toolkit/window_toolkit.dart';

void main() {
  test('insert adds characters at cursor', () {
    final ctrl = TextEditingController(text: 'hi');
    expect(ctrl.text, 'hi');
    expect(ctrl.cursor, 2);

    ctrl.insert('!');
    expect(ctrl.text, 'hi!');
    expect(ctrl.cursor, 3);
  });

  test('deleteLeft removes before cursor', () {
    final ctrl = TextEditingController(text: 'abc');
    ctrl.cursor = 2;
    ctrl.deleteLeft();
    expect(ctrl.text, 'ac');
    expect(ctrl.cursor, 1);
  });

  test('deleteRight removes after cursor', () {
    final ctrl = TextEditingController(text: 'abc');
    ctrl.cursor = 1;
    ctrl.deleteRight();
    expect(ctrl.text, 'ac');
    expect(ctrl.cursor, 1);
  });

  test('cursor navigation', () {
    final ctrl = TextEditingController(text: 'hello');
    ctrl.moveCursorLeft();
    expect(ctrl.cursor, 4);
    ctrl.moveCursorHome();
    expect(ctrl.cursor, 0);
    ctrl.moveCursorEnd();
    expect(ctrl.cursor, 5);
  });

  test('handleKey dispatches to insert and delete', () {
    final ctrl = TextEditingController();
    final mods = ModifierState(
      modsDepressed: 0,
      modsLatched: 0,
      modsLocked: 0,
      group: 0,
    );
    ctrl.handleKey(KeyEvent(0, true, mods, character: 'A'));
    expect(ctrl.text, 'A');
    ctrl.handleKey(KeyEvent(0, true, mods, character: 'b'));
    expect(ctrl.text, 'Ab');

    ctrl.handleKey(KeyEvent(42, true, mods)); // backspace
    expect(ctrl.text, 'A');
  });
}
