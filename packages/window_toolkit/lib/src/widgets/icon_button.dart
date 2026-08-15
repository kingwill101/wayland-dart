import '../drawing/color.dart';
import '../mixins/hoverable.dart';
import '../mixins/hover_animated.dart';
import '../painter/painter.dart';
import '../style.dart';
import '../style/style_patch.dart';
import '../widget.dart';
import 'image_icon.dart';

class IconButton extends Widget with Hoverable, HoverAnimated {
  IconShape shape;
  Color iconColor;
  Color backgroundColor;
  Color hoverColor;
  Color borderColor;
  int iconSize;
  VoidCallback? onPressed;

  IconButton(
    this.shape, {
    this.iconColor = const Color(255, 255, 255),
    this.backgroundColor = const Color(60, 60, 60),
    this.hoverColor = const Color(90, 90, 90),
    this.borderColor = const Color(30, 30, 30),
    this.iconSize = 16,
    this.onPressed,
  }) : assert(iconSize > 0, 'IconButton iconSize must be > 0') {
    width = iconSize + 12;
    height = iconSize + 12;
    onClick = () {
      press();
      return true;
    };
    tabIndex = 1;
  }

  void press() {
    onPressed?.call();
  }

  @override
  bool get acceptsFocus => true;

  @override
  Style styleRole() => Style(
    color: iconColor,
    backgroundColor: backgroundColor,
    borderColor: borderColor,
  );

  @override
  void draw(Painter canvas) {
    final base = resolvedStyle();
    final hover = resolvedStyleOn(const [
      'hover',
    ], local: StylePatch(backgroundColor: hoverColor));
    final fill = transitionHover(base.backgroundColor!, hover.backgroundColor!);
    canvas.drawRect(
      Rect.fromLTWH(
        x.toDouble(),
        y.toDouble(),
        width.toDouble(),
        height.toDouble(),
      ),
      Paint()..color = fill,
    );

    canvas.drawRect(
      Rect.fromLTWH(x.toDouble(), y.toDouble(), width.toDouble(), 1),
      Paint()..color = base.borderColor,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        x.toDouble(),
        (y + height - 1).toDouble(),
        width.toDouble(),
        1,
      ),
      Paint()..color = base.borderColor,
    );

    final cx = x + width ~/ 2;
    final cy = y + height ~/ 2;
    final half = iconSize ~/ 2;
    final paint = Paint()..color = base.color;

    switch (shape) {
      case IconShape.circle:
        canvas.drawCircle(
          Offset(cx.toDouble(), cy.toDouble()),
          half.toDouble(),
          paint,
        );
      case IconShape.square:
        canvas.drawRect(
          Rect.fromLTWH(
            (cx - half).toDouble(),
            (cy - half).toDouble(),
            iconSize.toDouble(),
            iconSize.toDouble(),
          ),
          paint,
        );
      case IconShape.triangle:
        canvas.drawLine(
          Offset(cx.toDouble(), (cy - half).toDouble()),
          Offset((cx - half).toDouble(), (cy + half).toDouble()),
          paint,
        );
        canvas.drawLine(
          Offset((cx - half).toDouble(), (cy + half).toDouble()),
          Offset((cx + half).toDouble(), (cy + half).toDouble()),
          paint,
        );
        canvas.drawLine(
          Offset((cx + half).toDouble(), (cy + half).toDouble()),
          Offset(cx.toDouble(), (cy - half).toDouble()),
          paint,
        );
    }
  }
}
