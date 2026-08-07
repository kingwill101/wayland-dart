import 'package:test/test.dart';
import 'package:window_toolkit/window_toolkit.dart';


void main() {
  test('VBoxLayout stacks children with spacing', () {
    final layout = VBoxLayout(
      spacing: 4,
      children: [
        Label('first')..height = 10,
        Label('second')..height = 20,
      ],
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

  test('BarLayout sizes spacers and keeps section alignment', () {
    final layout = BarLayout();
    final leftLabel = Label('L');
    final spacer = Spacer();
    final leftTail = Label('RR');
    final center = Label('C');
    final right = Label('X');

    layout.left.addAll([leftLabel, spacer, leftTail]);
    layout.center.add(center);
    layout.right.add(right);

    layout.layout(200, 30);

    expect(spacer.width, 160);
    expect(leftLabel.x, 0);
    expect(leftTail.x, 168);
    expect(center.x, 96);
    expect(right.x, 192);
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
    expect(rects, hasLength(5));
    expect(rects.first.rect.left, 1);
    expect(rects.first.rect.top, 2);
    expect(rects.first.rect.right, 41);
    expect(rects.first.rect.bottom, 32);
    expect(rects.first.paint.color, frame.color);
    expect(frame.hitTest(12, 13), isTrue);
    expect(frame.hitTest(3, 4), isFalse);
  });
}
