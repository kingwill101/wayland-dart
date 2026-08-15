import 'package:test/test.dart';
import 'package:window_toolkit/window_toolkit.dart';

void main() {
  test('HBox lays out children horizontally and forwards hit tests', () {
    final left = Label('A');
    final right = Label('BC');
    final hbox = HBox(spacing: 4, children: [left, right]);
    hbox.x = 10;
    hbox.y = 20;
    hbox.width = 100;
    hbox.height = 40;

    final painter = RecordingPainter();
    hbox.draw(painter);

    expect(left.x, 10);
    expect(left.y, 20);
    expect(right.x, 22);
    expect(right.y, 20);
    expect(hbox.hitTest(11, 21), isTrue);
    expect(hbox.hitTest(23, 21), isTrue);
    expect(hbox.hitTest(0, 0), isFalse);

    final texts = painter.commands.ofType<DrawTextCommand>().toList();
    expect(texts, hasLength(2));
    expect(texts[0].text, 'A');
    expect(texts[1].text, 'BC');
  });

  test('Align positions child within the available bounds', () {
    final child = Label('Z');
    final align = Align(
      child: child,
      horizontalAlignment: HorizontalAlignment.right,
      verticalAlignment: VerticalAlignment.bottom,
    );
    align.x = 5;
    align.y = 7;
    align.width = 100;
    align.height = 60;

    final painter = RecordingPainter();
    align.draw(painter);

    expect(child.x, 97);
    // child.y = y + height - child.height; child.height depends on font metrics
    expect(child.y, lessThan(align.y + align.height));
    expect(child.y, greaterThan(align.y));
    expect(align.hitTest(child.x + 1, child.y + 1), isTrue);
    expect(align.hitTest(6, 8), isFalse);

    final text = painter.commands.singleOfType<DrawTextCommand>();
    expect(text.text, 'Z');
    expect(text.position.dx, child.x.toDouble());
    // text position depends on font-metric vertical centering
    expect(text.position.dy, greaterThan(align.y.toDouble()));
  });

  test(
    'Padding insets the child and keeps hit tests inside the padded area',
    () {
      final child = Label('Pad');
      final padding = Padding(child: child, all: 10);
      padding.x = 3;
      padding.y = 4;
      padding.width = 80;
      padding.height = 50;

      final painter = RecordingPainter();
      padding.draw(painter);

      expect(child.x, 13);
      // child.y = padding.y + top; child.width/height depend on font metrics
      expect(child.y, greaterThan(padding.y));
      expect(child.width, greaterThan(1));
      expect(
        child.width,
        lessThanOrEqualTo(padding.width - padding.left - padding.right),
      );
      expect(padding.hitTest(child.x + 1, child.y + 1), isTrue);
      expect(padding.hitTest(4, 5), isFalse);

      final text = painter.commands.singleOfType<DrawTextCommand>();
      expect(text.text, 'Pad');
      expect(text.position.dx, child.x.toDouble());
      // text position depends on font-metric vertical centering
      expect(text.position.dy, greaterThan(padding.y.toDouble()));
    },
  );
}
