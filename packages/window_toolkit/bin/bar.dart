import 'package:window_toolkit/window_toolkit.dart';

class Bar extends LayerWindow {
  Timer? _clockTimer;

  Bar()
      : super(
          anchor: Anchor.top,
          barHeight: 30,
          exclusiveZone: 30,
        );

  @override
  void draw(Painter painter) {
    painter.clear(const Color(30, 30, 30));

    final now = DateTime.now();
    final time =
        '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}:'
        '${now.second.toString().padLeft(2, '0')}';

    painter.drawText(' Workspaces: 1 2 3 4 ', const Offset(0, 8),
        color: const Color(180, 180, 180), size: 14);
    painter.drawText(time, Offset(painter.width / 2 - 40, 8),
        color: const Color(200, 200, 200), size: 14);
    painter.drawText('vol 80%  bat 95%', Offset(painter.width - 160, 8),
        color: const Color(180, 180, 180), size: 14);
  }

  @override
  void onKeyPressed(KeyEvent event) {
    if (event.key == Key.esc.value) {
      _clockTimer?.cancel();
      Application.instance.quit();
    }
  }

  @override
  Future<void> show() async {
    _clockTimer =
        EventLoop.instance.addTimer(const Duration(seconds: 1), () {
      paint();
    });
    await super.show();
  }
}

void main() async {
  final bar = Bar();
  await bar.show();
  Application.instance.exec();
}
