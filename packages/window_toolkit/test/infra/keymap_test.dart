import 'package:test/test.dart';
import 'package:window_toolkit/window_toolkit.dart';

void main() {
  test('XkbKeyboard can be constructed', () {
    final kb = XkbKeyboard();
    expect(kb, isNotNull);
    kb.dispose();
  });

  test('keyEvent returns null when no keymap loaded', () {
    final kb = XkbKeyboard();
    final char = kb.keyEvent(30, true); // A key
    expect(char, isNull);
    kb.dispose();
  });

  test('keyEvent returns null for key release without keymap', () {
    final kb = XkbKeyboard();
    final char = kb.keyEvent(30, false);
    expect(char, isNull);
    kb.dispose();
  });
}
