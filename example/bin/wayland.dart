import 'dart:io';

import 'package:example/drawing/drawing.dart';
import 'package:example/window.dart';

class AppWindow extends Window {
  @override
  void paint(Canvas canvas) {
    print("window paint");
    final api = CanvasManager(canvas);

    api.addShape(Rectangle(
        0, 0, width, height, Color(255, 255, 255))); // White background

    api.addShape(Circle(
        100, 100, 20, Color(255, 0, 0, 255))); // Semi-transparent red circle
    api.addShape(Rectangle(100, 100, 200, 150,
        Color(0, 255, 0, 255))); // Semi-transparent green rectangle
    // api.addShape(Line(0, 0, 800, 600,
    //     Color(0, 0, 255, 128))); // Semi-transparent blue diagonal line
    api.addShape(Triangle(300, 100, 400, 300, 500, 200,
        Color(255, 255, 0, 255))); // Semi-transparent yellow triangle

    api.drawAll();
  }
}

void main() async {
  final app = AppWindow();
  app.title = "Wayland Example";
  app.show();
  exit(1);
}
