import 'package:test/test.dart';
import 'package:window_toolkit/window_toolkit.dart';

void main() {
  group('Dropdown', () {
    test('draws closed and calculates item positions', () {
      final dd = Dropdown(items: ['Alpha', 'Beta', 'Gamma'], selectedIndex: 1);
      dd.x = 5;
      dd.y = 6;
      dd.width = 140;
      dd.height = 22;

      final painter = RecordingPainter();
      dd.draw(painter);

      expect(painter.commands, isNotEmpty);
      expect(dd.selectedLabel, 'Beta');
      expect(dd.itemAt(10, 40), -1); // closed, no items hit

      // Open and check items
      dd.opened = true;
      painter.clearCommands();
      dd.draw(painter);
      expect(dd.itemAt(10, 35), 0); // first item y=6+22=28
    });

    test('selects an item and closes', () {
      final dd = Dropdown(items: ['A', 'B', 'C']);
      dd.select(1);
      expect(dd.selectedIndex, 1);
      expect(dd.opened, isFalse);
    });
  });

  group('ListBox', () {
    test('draws items and scrollbar when overflowing', () {
      final lb = ListBox(
        items: ['Item 1', 'Item 2', 'Item 3', 'Item 4', 'Item 5'],
        selectedIndex: 0,
      );
      lb.x = 2;
      lb.y = 3;
      lb.width = 120;
      lb.height = 50;

      final painter = RecordingPainter();
      lb.draw(painter);

      expect(painter.commands, isNotEmpty);
      expect(lb.itemAt(5, 25), 1);
      expect(lb.itemAt(200, 200), -1);

      lb.scrollBy(30);
      lb.draw(painter);
      expect(painter.commands, isNotEmpty);
    });

    test('selects an item', () {
      final lb = ListBox(items: ['One', 'Two']);
      lb.select(1);
      expect(lb.selectedIndex, 1);
    });
  });

  group('Menu', () {
    test('draws items and tracks hover', () {
      final a = MenuItem('Open');
      final b = MenuItem('Save');
      final menu = Menu(items: [a, b]);
      menu.x = 5;
      menu.y = 5;

      final painter = RecordingPainter();
      menu.draw(painter);

      expect(painter.commands, isNotEmpty);
      expect(menu.itemAt(10, 15), 0);
      expect(menu.hitTest(10, 15), isTrue);
      expect(menu.hitTest(0, 0), isFalse);
    });

    test('menu item triggers callback', () {
      var triggered = false;
      final item = MenuItem('Close', onTriggered: () => triggered = true);
      item.x = 5;
      item.y = 5;
      item.width = 60;
      item.height = 24;

      item.onClick?.call();
      expect(triggered, isTrue);
    });
  });

  group('Dialog', () {
    test('draws title, message, and buttons', () {
      final btn = DialogButton('OK');
      final dialog = Dialog(
        title: 'Confirm',
        message: 'Are you sure?',
        buttons: [btn],
      );
      dialog.x = 10;
      dialog.y = 10;

      final painter = RecordingPainter();
      dialog.draw(painter);

      expect(painter.commands, isNotEmpty);
      // hit test on a button area (buttons are at bottom-right)
      expect(dialog.hitTest(260, 100), isTrue);
      expect(dialog.hitTest(0, 0), isFalse);
    });

    test('dialog button fires callback', () {
      var fired = false;
      final btn = DialogButton('Yes', onPressed: () => fired = true);
      btn.onClick?.call();
      expect(fired, isTrue);
    });
  });
}
