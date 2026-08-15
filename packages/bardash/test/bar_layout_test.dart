import 'package:bardash/bardash.dart';
import 'package:test/test.dart';
import 'package:window_toolkit/window_toolkit.dart';

class _ModuleBox extends Widget {
  _ModuleBox(this.moduleWidth);

  final int moduleWidth;

  @override
  void measure(Painter painter) {
    width = moduleWidth;
    height = 14;
  }

  @override
  void draw(Painter canvas) {}
}

void main() {
  test('BarLayout composes left, centered, and right HBox regions', () {
    final left = _ModuleBox(40);
    final center = _ModuleBox(50);
    final right = _ModuleBox(60);
    final layout = BarLayout(spacing: 4)
      ..left.children.add(left)
      ..center.children.add(center)
      ..right.children.add(right)
      ..width = 400
      ..height = 30;

    final painter = RecordingPainter();
    layout.measure(painter);
    layout.performLayout(400);
    layout.draw(painter);

    expect(layout.left, isA<HBox>());
    expect(layout.center, isA<HBox>());
    expect(layout.right, isA<HBox>());
    expect(left.x, 0);
    expect(center.x, 175);
    expect(right.x, 340);
    expect(left.width, 40);
    expect(center.width, 50);
    expect(right.width, 60);
  });

  test('region children are exposed through the normal widget tree', () {
    final left = _ModuleBox(20);
    final center = _ModuleBox(30);
    final right = _ModuleBox(40);
    final layout = BarLayout()
      ..left.children.add(left)
      ..center.children.add(center)
      ..right.children.add(right);

    expect(layout.children, hasLength(3));
    expect(layout.children.every((child) => child is Positioned), isTrue);
    expect(layout.left.children, contains(same(left)));
    expect(layout.center.children, contains(same(center)));
    expect(layout.right.children, contains(same(right)));
  });
}
