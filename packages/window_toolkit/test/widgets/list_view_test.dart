import 'package:test/test.dart';
import 'package:window_toolkit/window_toolkit.dart';

void main() {
  group('ListView', () {
    test('lays out children vertically', () {
      final list = ListView(children: [
        Button('A'),
        Button('B'),
        Button('C'),
      ]);

      list.performLayout(100);
      expect(list.width, 100);
      expect(list.height, greaterThan(0));
    });

    test('draw records commands', () {
      final list = ListView(children: [
        Button('X'),
        Button('Y'),
      ]);

      final painter = RecordingPainter();
      list.width = 100;
      list.height = 200;
      list.draw(painter);

      final buttons = painter.commands.where((c) =>
          c.toString().contains('drawRect') || c.toString().contains('DrawRect'));
      expect(buttons.isNotEmpty, isTrue);
    });

    test('hitTest finds children', () {
      final list = ListView(children: [
        SizedBox(width: 100, height: 24, child: Button('Top')),
        SizedBox(width: 100, height: 24, child: Button('Bottom')),
      ]);

      list.x = 0;
      list.y = 0;
      list.width = 100;
      list.height = 200;
      list.performLayout(100);

      expect(list.hitTest(10, 10), isTrue);  // inside first child
      expect(list.hitTest(10, 30), isTrue);  // inside second child
      expect(list.hitTest(10, 100), isFalse); // outside content
    });
  });
}
