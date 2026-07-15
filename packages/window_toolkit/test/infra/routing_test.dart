import 'package:test/test.dart';
import 'package:window_toolkit/window_toolkit.dart';

class _TestWidget extends Widget {
  String id;
  int clicks = 0;
  int enters = 0;
  int leaves = 0;
  int downs = 0;
  int ups = 0;
  int drags = 0;
  int keyPresses = 0;
  final List<String> log = [];

  _TestWidget(this.id) {
    onClick = () { clicks++; log.add('click:$id'); return true; };
    onMouseEnter = () { enters++; log.add('enter:$id'); };
    onMouseLeave = () { leaves++; log.add('leave:$id'); };
  }

  @override
  void draw(Painter canvas) {
    canvas.drawRect(
      Rect.fromLTWH(x.toDouble(), y.toDouble(), width.toDouble(), height.toDouble()),
      Paint()..color = const Color(255, 0, 0),
    );
  }

  @override
  void onMouseDown(int x, int y, int button) { downs++; log.add('down:$id'); }
  @override
  void onMouseUp(int x, int y, int button) { ups++; log.add('up:$id'); }
  @override
  void onMouseDrag(int x, int y) { drags++; log.add('drag:$id'); }
  @override
  void onKeyPressed(KeyEvent event) { keyPresses++; log.add('key:$id'); }
}

void main() {
  test('WidgetWindow routes click to child widget', () {
    final child = _TestWidget('a')
      ..x = 10
      ..y = 10
      ..width = 40
      ..height = 30;
    final window = WidgetWindow(child);

    window.onMouseButtonPressed(MouseButtonEvent(15, 15, 272, true));
    expect(child.clicks, 1);
    expect(child.downs, 1);
    expect(child.log, contains('click:a'));
    expect(child.log, contains('down:a'));
  });

  test('WidgetWindow tracks hover enter/leave', () {
    final child = _TestWidget('b')
      ..x = 0
      ..y = 0
      ..width = 50
      ..height = 40;
    final window = WidgetWindow(child);

    window.onMouseMotion(MouseMotionEvent(10, 10));
    expect(child.enters, 1);

    window.onMouseMotion(MouseMotionEvent(60, 60));
    expect(child.leaves, 1);
  });

  test('WidgetWindow routes drag events to target', () {
    final child = _TestWidget('c')
      ..x = 0
      ..y = 0
      ..width = 50
      ..height = 40;
    final window = WidgetWindow(child);

    window.onMouseButtonPressed(MouseButtonEvent(10, 10, 272, true));
    expect(child.downs, 1);

    window.onMouseMotion(MouseMotionEvent(15, 15));
    expect(child.drags, 1);

    window.onMouseButtonReleased(MouseButtonEvent(15, 15, 272, false));
    expect(child.ups, 1);
  });
}
