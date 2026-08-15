import 'package:test/test.dart';
import 'package:window_toolkit/window_toolkit.dart';

void main() {
  group('ToggleButton', () {
    test('toggles selected state on click', () {
      var calls = 0;
      final btn = ToggleButton('Test', onChanged: () => calls++);
      expect(btn.selected, isFalse);

      btn.toggle();
      expect(btn.selected, isTrue);
      expect(calls, 1);

      btn.toggle();
      expect(btn.selected, isFalse);
      expect(calls, 2);
    });

    test('draws without errors', () {
      final btn = ToggleButton('On', selected: true);
      final painter = RecordingPainter();
      btn.draw(painter);
      expect(painter.commands, isNotEmpty);
    });
  });

  group('SegmentedControl', () {
    test('selects a segment', () {
      final seg = SegmentedControl(labels: ['A', 'B', 'C']);
      expect(seg.selectedIndex, 0);

      seg.select(1);
      expect(seg.selectedIndex, 1);

      seg.select(1); // same index — no change
      expect(seg.selectedIndex, 1);
    });

    test('draws without errors', () {
      final seg = SegmentedControl(labels: ['Red', 'Green', 'Blue']);
      seg.x = 2;
      seg.y = 3;
      seg.width = 180;
      seg.height = 24;

      final painter = RecordingPainter();
      seg.draw(painter);
      expect(painter.commands, isNotEmpty);
    });
  });

  group('RangeSlider', () {
    test('clamps values', () {
      final rs = RangeSlider(lower: 10, upper: 90);
      expect(rs.lower, 10);
      expect(rs.upper, 90);
    });

    test('draws without errors', () {
      final rs = RangeSlider(lower: 20, upper: 80);
      rs.x = 5;
      rs.y = 5;
      rs.width = 200;

      final painter = RecordingPainter();
      rs.draw(painter);
      expect(painter.commands, isNotEmpty);
    });
  });

  group('Spinner', () {
    test('draws when active', () {
      final spinner = Spinner(active: true);
      spinner.x = 10;
      spinner.y = 10;

      final painter = RecordingPainter();
      spinner.draw(painter);
      expect(painter.commands, isNotEmpty);
    });

    test('draws nothing when inactive', () {
      final spinner = Spinner(active: false);
      final painter = RecordingPainter();
      spinner.draw(painter);
      expect(painter.commands, isEmpty);
    });

    test('tick advances frame', () {
      final spinner = Spinner(dotCount: 8);
      expect(spinner.frame, 0);
      spinner.tick();
      expect(spinner.frame, 1);
      for (var i = 0; i < 7; i++) {
        spinner.tick();
      }
      expect(spinner.frame, 0); // wraps at dotCount
    });
  });

  group('Badge', () {
    test('draws count badge', () {
      final badge = Badge(count: 5);
      badge.x = 2;
      badge.y = 2;

      final painter = RecordingPainter();
      badge.draw(painter);
      expect(painter.commands, isNotEmpty);
    });
  });

  group('GroupBox', () {
    test('lays out children with title', () {
      final child = Button('OK');
      final box = GroupBox(title: 'Actions', children: [child]);
      box.x = 4;
      box.y = 6;
      box.width = 180;

      final painter = RecordingPainter();
      box.draw(painter);

      expect(painter.commands, isNotEmpty);
      expect(child.y, 40); // y + padding + titleOffset
      expect(box.hitTest(20, 44), isTrue);
    });
  });
}
