import '../drawing/color.dart';
import '../event_loop.dart';
import '../painter/painter.dart';
import '../style.dart';
import '../widget.dart';

class Spinner extends Widget {
  bool active;
  Color color;
  int dotCount;
  int dotRadius;
  int frame;
  int fps;

  Spinner({
    this.active = true,
    this.color = const Color(180, 180, 180),
    this.dotCount = 8,
    this.dotRadius = 3,
    this.frame = 0,
    this.fps = 20,
  }) {
    width = dotCount * dotRadius * 3;
    height = dotCount * dotRadius * 3;
  }

  @override
  Style styleRole() => Style(
    color: color,
    backgroundColor: const Color(0, 0, 0, 0),
    borderColor: color,
  );

  Timer? _timer;

  void start() {
    active = true;
    _timer?.cancel();
    _timer = EventLoop.instance.addTimer(
      Duration(milliseconds: (1000 / fps).round()),
      tick,
    );
  }

  void stop() {
    active = false;
    _timer?.cancel();
    _timer = null;
  }

  void tick() {
    frame = (frame + 1) % dotCount;
  }

  @override
  void draw(Painter canvas) {
    if (!active) return;
    final baseColor = resolvedStyle().color;

    final cx = x + width ~/ 2;
    final cy = y + height ~/ 2;
    final radius = (width < height ? width : height) ~/ 2 - dotRadius;

    for (var i = 0; i < dotCount; i++) {
      final angle = (i / dotCount) * 3.14159 * 2;
      final offset = ((i + frame) % dotCount) / dotCount;
      final alpha = (255 * offset).round();
      final dotColor = Color(baseColor.r, baseColor.g, baseColor.b, alpha);
      final dx = (cx + (radius * cos(angle)).round()).toDouble();
      final dy = (cy + (radius * sin(angle)).round()).toDouble();
      canvas.drawCircle(
        Offset(dx, dy),
        dotRadius.toDouble(),
        Paint()..color = dotColor,
      );
    }
  }

  double cos(double rad) => _cos(rad);
  double sin(double rad) => _sin(rad);

  static double _cos(double a) {
    a += _pi / 2;
    if (a > _pi) a -= _pi * 2;
    final a2 = a * a;
    return 1 - a2 / 2 + a2 * a2 / 24 - a2 * a2 * a2 / 720;
  }

  static double _sin(double a) {
    if (a > _pi) a -= _pi * 2;
    final a3 = a * a * a;
    return a - a3 / 6 + a3 * a * a / 120 - a3 * a3 * a / 5040;
  }

  static const double _pi = 3.1415926535897932;
}
