import 'package:test/test.dart';
import 'package:window_toolkit/window_toolkit.dart';

void main() {
  group('AnimatedOpacity', () {
    test('draws child', () {
      final ao = AnimatedOpacity(child: Label('Test'), opacity: 1.0);
      ao.x = 0;
      ao.y = 0;
      ao.width = 100;
      ao.height = 24;

      final painter = RecordingPainter();
      ao.draw(painter);

      final texts = painter.commands.ofType<DrawTextCommand>().toList();
      expect(texts, hasLength(1));
      expect(texts[0].text, 'Test');
    });

    test('hitTest delegates to child', () {
      final ao = AnimatedOpacity(
        child: SizedBox(width: 100, height: 24, child: Label('Hit')),
      );
      ao.x = 0;
      ao.y = 0;
      ao.width = 100;
      ao.height = 24;

      expect(ao.hitTest(10, 12), isTrue);
      expect(ao.hitTest(200, 12), isFalse);
    });
  });

  group('AnimatedSlide', () {
    test('draws child at offset', () {
      final as = AnimatedSlide(
        child: Label('Slide'),
        delta: const Offset(50, 0),
      );
      as.x = 10;
      as.y = 20;
      as.width = 100;
      as.height = 24;

      final painter = RecordingPainter();
      as.draw(painter);

      final texts = painter.commands.ofType<DrawTextCommand>().toList();
      expect(texts, hasLength(1));
      expect(texts[0].text, 'Slide');
    });

    test('performs layout', () {
      final as = AnimatedSlide(
        child: SizedBox(width: 80, height: 24, child: Label('Wide')),
      );
      as.performLayout(200);
      expect(as.width, 200);
      expect(as.height, greaterThan(0));
    });
  });

  group('AnimatedContainer', () {
    test('draws background rect', () {
      final ac = AnimatedContainer(
        color: const Color(30, 30, 30),
        boxWidth: 100,
        boxHeight: 50,
      );
      ac.x = 5;
      ac.y = 10;

      final painter = RecordingPainter();
      ac.draw(painter);

      final rects = painter.commands.ofType<DrawRectCommand>().toList();
      expect(rects, hasLength(1));
      expect(rects[0].rect.left, 5);
      expect(rects[0].rect.top, 10);
      expect(rects[0].rect.width, 100);
      expect(rects[0].rect.height, 50);
    });

    test('draws child inside padding', () {
      final ac = AnimatedContainer(
        color: const Color(0, 0, 0),
        boxWidth: 80,
        boxHeight: 30,
        padL: 8,
        padT: 4,
        child: Label('Pad'),
      );
      ac.performLayout(100);

      final painter = RecordingPainter();
      ac.draw(painter);

      final texts = painter.commands.ofType<DrawTextCommand>().toList();
      expect(texts, hasLength(1));
      expect(texts[0].text, 'Pad');
    });

    test('hitTest works with child', () {
      final ac = AnimatedContainer(
        color: const Color(0, 0, 0),
        boxWidth: 100,
        boxHeight: 50,
        child: SizedBox(width: 80, height: 30, child: Label('Hit')),
      );
      ac.x = 0;
      ac.y = 0;
      ac.performLayout(100);
      expect(ac.hitTest(50, 25), isTrue);
      expect(ac.hitTest(200, 200), isFalse);
    });
  });

  group('AnimatedCrossFade', () {
    test('draws first child by default', () {
      final cf = AnimatedCrossFade(
        firstChild: Label('First'),
        secondChild: Label('Second'),
      );
      final painter = RecordingPainter();
      cf.draw(painter);

      final texts = painter.commands.ofType<DrawTextCommand>().toList();
      expect(texts, hasLength(1));
      expect(texts[0].text, 'First');
    });

    test('draws second child when showFirst=false', () {
      final cf = AnimatedCrossFade(
        firstChild: Label('First'),
        secondChild: Label('Second'),
        showFirst: false,
      );
      final painter = RecordingPainter();
      cf.draw(painter);

      final texts = painter.commands.ofType<DrawTextCommand>().toList();
      expect(texts, hasLength(1));
      expect(texts[0].text, 'Second');
    });

    test('performs layout', () {
      final cf = AnimatedCrossFade(
        firstChild: SizedBox(width: 100, height: 30, child: Label('A')),
        secondChild: SizedBox(width: 100, height: 50, child: Label('B')),
      );
      cf.performLayout(200);
      expect(cf.width, 200);
      expect(cf.height, 50); // max of both
    });
  });
}
