import 'dart:typed_data';

import './color.dart';
import './shape.dart';

class Canvas {
  final int width;
  final int height;
  final PixelFormat format;
  final Uint8List pixels;

  Canvas(this.width, this.height, this.format)
      : pixels = Uint8List(width * height * _formatSize(format));

  static int _formatSize(PixelFormat format) {
    switch (format) {
      case PixelFormat.rgb:
        return 3;
      case PixelFormat.rgba:
        return 4;
      case PixelFormat.grayscale:
        return 1;
      case PixelFormat.argb8888:
        return 4;
      default:
        throw ArgumentError('Unsupported PixelFormat: $format');
    }
  }

  Color getPixel(int x, int y) {
    if (x < 0 || x >= width || y < 0 || y >= height) return Color(0, 0, 0, 0);
    final index = (y * width + x) * _formatSize(format);
    switch (format) {
      case PixelFormat.rgb:
        return Color(pixels[index], pixels[index + 1], pixels[index + 2]);
      case PixelFormat.rgba:
        return Color(pixels[index], pixels[index + 1], pixels[index + 2],
            pixels[index + 3]);
      case PixelFormat.grayscale:
        return Color(pixels[index], pixels[index], pixels[index]);
      case PixelFormat.argb8888:
        return Color.fromArgb8888(Uint32List.view(pixels.buffer)[y * width + x]);
      default:
        throw ArgumentError('Unsupported PixelFormat: $format');
    }
  }

  void setPixel(int x, int y, Color color) {
    if (x < 0 || x >= width || y < 0 || y >= height) return;
    final index = y * width + x;
    switch (format) {
      case PixelFormat.rgb:
      case PixelFormat.rgba:
      case PixelFormat.grayscale:
        final colorList = color.toList(format);
        for (int i = 0; i < colorList.length; i++) {
          pixels[index * _formatSize(format) + i] = colorList[i];
        }
        break;
      case PixelFormat.argb8888:
        Uint32List.view(pixels.buffer)[index] = color.toArgb8888();
        break;
    }
  }
}

class CanvasManager {
  final Canvas area;
  final List<Shape> shapes = [];

  CanvasManager(this.area);

  void addShape(Shape shape) {
    shapes.add(shape);
  }

  void drawAll() {
    for (var shape in shapes) {
      shape.draw(area);
    }
  }

  List<Shape> detectCollisions() {
    List<Shape> collidingShapes = [];
    for (int i = 0; i < shapes.length; i++) {
      for (int j = i + 1; j < shapes.length; j++) {
        if (shapes[i].collidesWith(shapes[j])) {
          collidingShapes.add(shapes[i]);
          collidingShapes.add(shapes[j]);
        }
      }
    }
    return collidingShapes;
  }
}
