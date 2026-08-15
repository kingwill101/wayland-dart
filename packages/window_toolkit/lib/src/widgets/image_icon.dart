import '../widget.dart';
import '../drawing/color.dart';
import '../painter/painter.dart';
import '../style.dart';

enum IconShape { circle, square, triangle }

class ImageIcon extends Widget {
  IconShape shape;
  Color iconColor;
  int size;

  ImageIcon(
    this.shape, {
    this.iconColor = const Color(255, 255, 255),
    this.size = 16,
  }) : assert(size > 0, 'ImageIcon size must be > 0'),
       super() {
    width = size;
    height = size;
  }

  @override
  Style styleRole() => Style(
    color: iconColor,
    backgroundColor: const Color(0, 0, 0, 0),
    borderColor: iconColor,
    borderWidth: 0,
  );

  @override
  void draw(Painter canvas) {
    final style = resolvedStyle();
    final c = styledColor(style.color, style);
    final cx = x + width ~/ 2;
    final cy = y + height ~/ 2;

    switch (shape) {
      case IconShape.circle:
        final radius = size ~/ 2;
        canvas.drawCircle(
          Offset(cx.toDouble(), cy.toDouble()),
          radius.toDouble(),
          Paint()..color = c,
        );
      case IconShape.square:
        canvas.drawRect(
          Rect.fromLTWH(
            x.toDouble(),
            y.toDouble(),
            width.toDouble(),
            height.toDouble(),
          ),
          Paint()..color = c,
        );
      case IconShape.triangle:
        canvas.drawRect(
          Rect.fromLTWH(
            x.toDouble(),
            y.toDouble(),
            width.toDouble(),
            height.toDouble(),
          ),
          Paint()..color = c,
        );
    }
  }
}
