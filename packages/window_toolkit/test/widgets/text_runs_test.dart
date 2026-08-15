import 'package:test/test.dart';
import 'package:window_toolkit/window_toolkit.dart';

void main() {
  setUp(FontDatabase.instance.useBitmapEngine);

  test('measures and draws icon and UI runs from one widget', () {
    final widget = TextRuns(
      '\u{f028} 55%',
      textFont: const Font.ui(pixelSize: 13),
      iconFont: const Font.icon(pixelSize: 14),
      color: const Color(255, 0, 0),
    );
    final painter = RecordingPainter(width: 320, height: 30);

    widget.measure(painter);
    widget
      ..x = 4
      ..y = 0
      ..height = 30;
    widget.draw(painter);

    expect(widget.width, greaterThan(0));
    final text = painter.commands.whereType<DrawTextCommand>().toList();
    expect(text, hasLength(2));
    expect(text[0].text, '\u{f028}');
    expect(text[1].text, ' 55%');
    expect(text.every((command) => command.color?.r == 255), isTrue);
  });

  test('updates intrinsic width when formatted output changes', () {
    final widget = TextRuns('55%');
    final painter = RecordingPainter(width: 320, height: 30);

    widget.measure(painter);
    final short = widget.width;
    widget.text = 'Volume 100%';
    widget.measure(painter);

    expect(widget.width, greaterThan(short));
  });
}
