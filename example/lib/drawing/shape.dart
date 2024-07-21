import 'dart:math' as math;

import 'drawing.dart';

abstract class Shape {
  Color color;

  Shape(this.color);

  void draw(Canvas area);

  bool collidesWith(Shape other);
}

class Circle extends Shape {
  int centerX, centerY, radius;

  Circle(this.centerX, this.centerY, this.radius, Color color) : super(color);

  @override
  void draw(Canvas area) {
    for (int y = centerY - radius; y <= centerY + radius; y++) {
      for (int x = centerX - radius; x <= centerX + radius; x++) {
        if (math.pow(x - centerX, 2) + math.pow(y - centerY, 2) <=
            math.pow(radius, 2)) {
          area.setPixel(x, y, color);
        }
      }
    }
  }

  @override
  bool collidesWith(Shape other) {
    if (other is Circle) {
      int distanceX = (centerX - other.centerX).abs();
      int distanceY = (centerY - other.centerY).abs();
      int distance =
          math.sqrt(distanceX * distanceX + distanceY * distanceY).toInt();
      return distance <= (radius + other.radius);
    }
    // Add collision detection for other shapes as needed
    return false;
  }
}

class Rectangle extends Shape {
  int x, y, width, height;

  Rectangle(this.x, this.y, this.width, this.height, Color color)
      : super(color);

  @override
  void draw(Canvas area) {
    for (int dy = 0; dy < height; dy++) {
      for (int dx = 0; dx < width; dx++) {
        area.setPixel(x + dx, y + dy, color);
      }
    }
  }

  @override
  bool collidesWith(Shape other) {
    if (other is Rectangle) {
      return x < other.x + other.width &&
          x + width > other.x &&
          y < other.y + other.height &&
          y + height > other.y;
    }
    // Add collision detection for other shapes as needed
    return false;
  }
}

class Line extends Shape {
  int x1, y1, x2, y2;

  Line(this.x1, this.y1, this.x2, this.y2, Color color) : super(color);

  @override
  void draw(Canvas area) {
    int dx = (x2 - x1).abs();
    int dy = (y2 - y1).abs();
    int sx = x1 < x2 ? 1 : -1;
    int sy = y1 < y2 ? 1 : -1;
    int err = dx - dy;

    while (true) {
      area.setPixel(x1, y1, color);
      if (x1 == x2 && y1 == y2) break;
      int e2 = 2 * err;
      if (e2 > -dy) {
        err -= dy;
        x1 += sx;
      }
      if (e2 < dx) {
        err += dx;
        y1 += sy;
      }
    }
  }

  @override
  bool collidesWith(Shape other) {
    // Implement line collision detection if needed
    return false;
  }
}

class Triangle extends Shape {
  int x1, y1, x2, y2, x3, y3;

  Triangle(this.x1, this.y1, this.x2, this.y2, this.x3, this.y3, Color color)
      : super(color);

  @override
  void draw(Canvas area) {
    // Sort vertices by y-coordinate
    if (y1 > y2) {
      int temp = y1;
      y1 = y2;
      y2 = temp;
      temp = x1;
      x1 = x2;
      x2 = temp;
    }
    if (y1 > y3) {
      int temp = y1;
      y1 = y3;
      y3 = temp;
      temp = x1;
      x1 = x3;
      x3 = temp;
    }
    if (y2 > y3) {
      int temp = y2;
      y2 = y3;
      y3 = temp;
      temp = x2;
      x2 = x3;
      x3 = temp;
    }

    int dx1 = (x2 - x1) as int, dy1 = (y2 - y1) as int;
    int dx2 = (x3 - x1) as int, dy2 = (y3 - y1) as int;
    int dx3 = (x3 - x2) as int, dy3 = (y3 - y2) as int;

    for (int y = y1; y <= y3; y++) {
      int xl, xr;
      if (y < y2) {
        xl = x1 + ((y - y1) * dx1 / dy1).round();
        xr = x1 + ((y - y1) * dx2 / dy2).round();
      } else {
        xl = x2 + ((y - y2) * dx3 / dy3).round();
        xr = x1 + ((y - y1) * dx2 / dy2).round();
      }
      if (xl > xr) {
        int temp = xl;
        xl = xr;
        xr = temp;
      }
      for (int x = xl; x <= xr; x++) {
        area.setPixel(x, y, color);
      }
    }
  }

  @override
  bool collidesWith(Shape other) {
    // Implement triangle collision detection if needed
    return false;
  }
}
