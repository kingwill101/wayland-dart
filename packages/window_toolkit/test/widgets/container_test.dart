import 'package:test/test.dart';
import 'package:window_toolkit/window_toolkit.dart';

class _Box extends Widget {
  _Box(this.boxWidth, this.boxHeight);

  final int boxWidth;
  final int boxHeight;

  @override
  void performLayout(int containerWidth) {
    width = boxWidth;
    height = boxHeight;
  }

  @override
  void draw(Painter canvas) {}
}

void main() {
  group('Container', () {
    test('hosts ordinary children without imposing a bar layout policy', () {
      final child = _Box(40, 12);
      final container = Container(children: [child])
        ..width = 100
        ..height = 30;

      container.performLayout(100);

      expect(container.children, contains(same(child)));
      expect(child.parent, same(container));
      expect(child.width, 40);
      expect(child.height, 12);
      expect(container.hitTest(10, 10), isTrue);
      expect(container.hitTest(90, 25), isTrue);
      expect(container.hitTest(101, 10), isFalse);
    });

    test('does not expand a child that owns its intrinsic size', () {
      final first = _Box(48, 14);
      final second = _Box(64, 18);
      final container = Container(children: [first, second])
        ..width = 800
        ..height = 30;

      container.performLayout(800);

      expect(first.width, 48);
      expect(second.width, 64);
      expect(first.x, 0);
      expect(second.x, 0);
    });
  });
}
