import 'package:test/test.dart';
import 'package:window_toolkit/window_toolkit.dart';

void main() {
  group('AnimatedOpacity', () {
    test('draws child', () {
      final ao = AnimatedOpacity(
        child: Label('Test'),
        opacity: 1.0,
      );
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
}
