import 'package:test/test.dart';
import 'package:window_toolkit/window_toolkit.dart';

void main() {
  test('WrapLayout wraps children to multiple runs', () {
    final wrap = WrapLayout(
      spacing: 4,
      runSpacing: 6,
      children: [Label('AA'), Label('BBB'), Label('CCCC')],
    );
    wrap.x = 10;
    wrap.y = 20;
    wrap.width = 40;

    wrap.layout(wrap.width, 0);

    expect(wrap.children[0].x, 10);
    expect(wrap.children[0].y, 20);
    expect(wrap.children[1].x, 10);
    expect(wrap.children[1].y, 42);
    expect(wrap.children[2].x, 10);
    expect(wrap.children[2].y, 64);
    expect(wrap.height, 60);
  });

  test('WrapLayout hit tests child bounds', () {
    final wrap = WrapLayout(
      spacing: 4,
      runSpacing: 6,
      children: [Label('AA'), Label('BBB')],
    );
    wrap.x = 10;
    wrap.y = 20;
    wrap.width = 60;
    wrap.height = 80;

    expect(wrap.hitTest(11, 21), isTrue);
    expect(wrap.hitTest(100, 100), isFalse);
  });

  test('WrapLayout draws children without errors', () {
    final wrap = WrapLayout(
      spacing: 4,
      runSpacing: 6,
      children: [Button('One'), Button('Two'), Button('Three')],
    );
    wrap.x = 0;
    wrap.y = 0;
    wrap.width = 120;

    final painter = RecordingPainter();
    wrap.draw(painter);

    expect(painter.commands, isNotEmpty);
  });
}
