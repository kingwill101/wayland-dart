enum PixelFormat {
  rgb,
  rgba,
  grayscale,
  argb8888
}

class Color {
  final int a, r, g, b;
  
  const Color(this.r, this.g, this.b, [this.a = 255]);

  factory Color.fromArgb8888(int argb) {
    return Color(
      (argb >> 16) & 0xFF,
      (argb >> 8) & 0xFF,
      argb & 0xFF,
      (argb >> 24) & 0xFF,
    );
  }

  int toArgb8888() {
    return (a << 24) | (r << 16) | (g << 8) | b;
  }

  List<int> toList(PixelFormat format) {
    switch (format) {
      case PixelFormat.rgb: return [r, g, b];
      case PixelFormat.rgba: return [r, g, b, a];
      case PixelFormat.grayscale: return [(r + g + b) ~/ 3];
      case PixelFormat.argb8888: return [toArgb8888()];
    }
  }

  static Color blend(Color background, Color foreground) {
    final alpha = foreground.a / 255;
    final invAlpha = 1 - alpha;
    return Color(
      (foreground.r * alpha + background.r * invAlpha).round(),
      (foreground.g * alpha + background.g * invAlpha).round(),
      (foreground.b * alpha + background.b * invAlpha).round(),
      255,
    );
  }
}
