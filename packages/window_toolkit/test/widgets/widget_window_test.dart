import 'package:test/test.dart';
import 'package:window_toolkit/window_toolkit.dart';

class _Child extends Widget {
  String id;
  int enters = 0;
  int leaves = 0;
  int clicks = 0;

  _Child(this.id) {
    onClick = () {
      clicks++;
    };
    onMouseEnter = () {
      enters++;
    };
    onMouseLeave = () {
      leaves++;
    };
  }

  @override
  void draw(Painter canvas) {
    canvas.drawRect(
      Rect.fromLTWH(x.toDouble(), y.toDouble(), width.toDouble(), height.toDouble()),
      Paint()..color = const Color(255, 0, 0),
    );
  }
}

void main() {
  test('WidgetWindow hit tests and routes hover events', () {
    final child = _Child('c')
      ..x = 10
      ..y = 10
      ..width = 40
      ..height = 30;

    final window = WidgetWindow(child);

    // Inside child bounds → mouse enter fires
    window.onMouseMotion(MouseMotionEvent(15, 15));
    expect(child.enters, 1);

    // Same widget → no duplicate enter
    window.onMouseMotion(MouseMotionEvent(20, 20));
    expect(child.enters, 1);

    // Leave child bounds → mouse leave fires
    window.onMouseMotion(MouseMotionEvent(5, 5));
    expect(child.leaves, 1);
  });

  test('WidgetWindow routes click events to the hit widget', () {
    final child = _Child('c')
      ..x = 10
      ..y = 10
      ..width = 40
      ..height = 30;

    final window = WidgetWindow(child);

    window.onMouseButtonPressed(MouseButtonEvent(15, 15, 272, true));
    expect(child.clicks, 1);
  });

  test('WidgetWindow tracks focus across clicks', () {
    final a = _Child('a')
      ..x = 0
      ..y = 0
      ..width = 20
      ..height = 40;
    final b = _Child('b')
      ..x = 30
      ..y = 0
      ..width = 20
      ..height = 40;

    final container = Frame(children: [a, b]);
    container.x = 0;
    container.y = 0;
    container.width = 100;
    container.height = 60;

    final window = WidgetWindow(container);

    expect(window.focus.hasFocus, isFalse);

    // Click inside root bounds — focuses the root
    window.onMouseButtonPressed(MouseButtonEvent(10, 10, 272, true));
    expect(window.focus.hasFocus, isTrue);
  });
}
