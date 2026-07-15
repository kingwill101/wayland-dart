import 'package:test/test.dart';
import 'package:window_toolkit/window_toolkit.dart';

import '../support/widget_test_harness.dart';

void main() {
  group('Dialog', () {
    test('title is stored', () {
      final d = Dialog(title: 'Confirm', message: 'Sure?');
      expect(d.title, 'Confirm');
    });

    test('message is stored', () {
      final d = Dialog(message: 'Are you sure?');
      expect(d.message, 'Are you sure?');
    });

    test('buttons are created', () {
      final d = Dialog(
        title: 'Save?',
        message: 'Save changes?',
        buttons: [
          DialogButton('Yes'),
          DialogButton('No'),
          DialogButton('Cancel'),
        ],
      );
      expect(d.buttons.length, 3);
    });

    test('draw records commands', () {
      final harness = WidgetHarness(Dialog(
        message: 'Hello',
      ));
      harness.draw();
      expect(harness.painter.commands, isNotEmpty);
    });
  });

  group('DialogButton', () {
    test('label is stored', () {
      final db = DialogButton('OK');
      expect(db.label, 'OK');
    });

    test('onPressed fires', () {
      int count = 0;
      final db = DialogButton('OK', onPressed: () => count++);
      db.onClick?.call();
      expect(count, 1);
    });
  });
}
