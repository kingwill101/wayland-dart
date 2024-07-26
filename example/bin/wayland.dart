import 'dart:math';

import 'package:example/drawing/drawing.dart';
import 'package:example/event_loop.dart';
import 'package:example/widget.dart';
import 'package:example/window.dart';

class AppWindow extends Window {
  @override
  void onEvent(Event event) {
    super.onEvent(event);
    print(event);
  }

  @override
  void paint(Canvas canvas) {
    print("window paint");
    final api = CanvasManager(canvas);
    api.addShape(Rectangle(
        0, 0, width, height, Color(255, 255, 255))); // White background

    for (var i = 0; i < 100000; i++) {
      // Assuming you have defined the following ranges
      const minX = 0, maxX = 800;
      const minY = 0, maxY = 600;
      const minRadius = 10, maxRadius = 50;

// Generate random position
      final randomX = minX + Random().nextInt(maxX );
      final randomY = minY + Random().nextInt(maxY );

// Generate random radius
      final randomRadius =
          minRadius + Random().nextInt(maxRadius - minRadius);

// Generate random color
      final randomColor = Color(
        Random().nextInt(256), // Random red value
        Random().nextInt(256), // Random green value
        Random().nextInt(256), // Random blue value
      );

// Add the circle with random properties
      api.addShape(Circle(
          randomX, randomY, randomRadius, randomColor));
    }

    api.drawAll();
  }

  @override
  onKeyPressed(KeyEvent event) {
    print(event.key);
    // if (event.key == Key.esc.value) {
    //   shouldExit = true;
    // }
  }
}

void main() async {
  final app = AppWindow();
  app.title = "Wayland Example";
  EventLoop.instance.run();
  // Application.instance.run();
  while (true) {
    // print("");
  }
}
