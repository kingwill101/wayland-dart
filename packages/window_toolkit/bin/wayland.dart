import 'dart:math';

import 'package:window_toolkit/window_toolkit.dart';

class AppWindow extends Window {
  @override
  void draw(Painter painter) {
    painter.clear(const Color(255, 255, 255));

    final rng = Random();
    for (var i = 0; i < 200; i++) {
      final cx = rng.nextDouble() * painter.width;
      final cy = rng.nextDouble() * painter.height;
      final r = 10 + rng.nextDouble() * 40;
      final c = Color(rng.nextInt(256), rng.nextInt(256), rng.nextInt(256));
      painter.drawCircle(Offset(cx, cy), r, Paint()..color = c);
    }
  }

  @override
  void onKeyPressed(KeyEvent event) {
    if (event.key == Key.esc.value) {
      Application.instance.quit();
    }
  }
}

void main() async {
  final window = AppWindow();
  await window.show();
  Application.instance.exec();
}
