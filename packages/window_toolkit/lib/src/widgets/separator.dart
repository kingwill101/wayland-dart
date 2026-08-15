import '../drawing/color.dart';
import '../painter/painter.dart';
import '../style.dart';
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
  Style styleRole() => Style(
    color: color,
    backgroundColor: const Color(0, 0, 0, 0),
    borderColor: color,
  );

  @override
  void draw(Painter canvas) {
    final lineColor = resolvedStyle().color;
    final lineX = (x + margin).toDouble();
    canvas.drawRect(
      Rect.fromLTWH(
        lineX,
        y.toDouble(),
        lineWidth.toDouble(),
        height.toDouble(),
      ),
      Paint()..color = lineColor,
    );
  }
}
