import '../widget.dart';
import '../drawing/color.dart';
import '../painter/painter.dart';

enum IconShape { circle, square, triangle }

class ImageIcon extends Widget {
  IconShape shape;
  Color iconColor;
  int size;

  ImageIcon(this.shape,
      {this.iconColor = const Color(255, 255, 255), this.size = 16})
      : super() {
    width = size;
    height = size;
  }

  @override
  void draw(Painter canvas) {
    final c = iconColor;
    final cx = x + width ~/ 2;
    final cy = y + height ~/ 2;

    switch (shape) {
      case IconShape.circle:
        final radius = size ~/ 2;
        canvas.drawCircle(Offset(cx.toDouble(), cy.toDouble()),
            radius.toDouble(),
            Paint()..color = c);
      case IconShape.square:
        canvas.drawRect(
            Rect.fromLTWH(x.toDouble(), y.toDouble(), width.toDouble(),
                height.toDouble()),
            Paint()..color = c);
      case IconShape.triangle:
        canvas.drawRect(
            Rect.fromLTWH(x.toDouble(), y.toDouble(), width.toDouble(),
                height.toDouble()),
            Paint()..color = c);
    }
  }
}
