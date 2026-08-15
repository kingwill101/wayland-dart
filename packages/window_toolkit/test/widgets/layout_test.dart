import 'package:test/test.dart';
import 'package:window_toolkit/window_toolkit.dart';

void main() {
  test('VBoxLayout stacks children with spacing', () {
    final layout = VBoxLayout(
      spacing: 4,
      children: [Label('first')..height = 10, Label('second')..height = 20],
    );
    layout.x = 10;
    layout.y = 20;
    layout.width = 120;

    layout.layout();

    expect(layout.height, 34);
    expect(layout.children[0].x, 10);
    expect(layout.children[0].y, 20);
    expect(layout.children[0].width, 120);
    expect(layout.children[1].x, 10);
    expect(layout.children[1].y, 34);
    expect(layout.children[1].width, 120);
    expect(layout.hitTest(12, 22), isTrue);
    expect(layout.hitTest(12, 36), isTrue);
    expect(layout.hitTest(0, 0), isFalse);
  });

  test('Frame draws background, border, and respects child hit testing', () {
    final child = Label('child');
    child.x = 10;
    child.y = 12;

    final frame = Frame(
      color: const Color(10, 20, 30),
      borderWidth: 2,
      borderColor: const Color(40, 50, 60),
      children: [child],
    );
    frame.x = 1;
    frame.y = 2;
    frame.width = 40;
    frame.height = 30;

    final painter = RecordingPainter();
    frame.draw(painter);

    final rects = painter.commands.ofType<DrawRectCommand>().toList();
    // Frame delegates its surface to the shared styled-box renderer: one
    // filled rect and one stroked rect for the border.
    expect(rects, hasLength(2));
    expect(rects.first.rect.left, 1);
    expect(rects.first.rect.top, 2);
    expect(rects.first.rect.right, 41);
    expect(rects.first.rect.bottom, 32);
    expect(rects.first.paint.color.toArgb8888(), frame.color.toArgb8888());
    expect(frame.hitTest(12, 13), isTrue);
    expect(frame.hitTest(3, 4), isFalse);
  });
}
