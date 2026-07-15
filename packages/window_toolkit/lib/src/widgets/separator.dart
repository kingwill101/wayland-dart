import '../drawing/color.dart';
import '../painter/painter.dart';
import '../widget.dart';

class Separator extends Widget {
  Color color;
  int lineWidth;
  int margin;

  Separator({
    this.color = const Color(80, 80, 80),
    this.lineWidth = 1,
    this.margin = 3,
  }) {
    width = lineWidth + margin * 2;
  }

  @override
  void draw(Painter canvas) {
    final lineX = (x + margin).toDouble();
    canvas.drawRect(
        Rect.fromLTWH(lineX, y.toDouble(), lineWidth.toDouble(),
            height.toDouble()),
        Paint()..color = color);
  }
}
