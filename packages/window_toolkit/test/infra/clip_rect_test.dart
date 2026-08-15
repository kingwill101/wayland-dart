import 'package:test/test.dart';
import 'package:window_toolkit/window_toolkit.dart';

void main() {
  test('RecordingPainter records ClipRectCommand', () {
    final painter = RecordingPainter(width: 400, height: 300);
    painter.clipRect(const Rect.fromLTWH(10, 20, 100, 50));

    final clips = painter.commands.whereType<ClipRectCommand>().toList();
    expect(clips, hasLength(1));
    expect(clips.single.rect.left, 10);
    expect(clips.single.rect.top, 20);
    expect(clips.single.rect.right, 110);
    expect(clips.single.rect.bottom, 70);
  });

  test('clipRect is recorded with transform', () {
    final painter = RecordingPainter();
    painter.save();
    painter.translate(5, 8);
    painter.clipRect(const Rect.fromLTWH(0, 0, 30, 20));
    painter.restore();

    final clips = painter.commands.whereType<ClipRectCommand>().toList();
    expect(clips, hasLength(1));
    expect(clips.single.rect.left, 5);
    expect(clips.single.rect.top, 8);
  });

  test('ScrollArea uses clipRect', () {
    final content = Label('Tall')..height = 200;
    final scroll = ScrollArea(child: content);
    scroll.x = 2;
    scroll.y = 3;
    scroll.width = 100;
    scroll.height = 50;

    final painter = RecordingPainter();
    scroll.draw(painter);

    final clips = painter.commands.whereType<ClipRectCommand>().toList();
    expect(clips, isNotEmpty);
    expect(clips.first.rect.left, 2);
    expect(clips.first.rect.top, 3);
    expect(clips.first.rect.right, 102);
    expect(clips.first.rect.bottom, 53);
  });
}
