import '../drawing/color.dart';
import '../font/font.dart';
import '../mixins/hoverable.dart';
import '../mixins/hover_animated.dart';
import '../painter/painter.dart';
import '../style.dart';
import '../style/style_patch.dart';
import '../widget.dart';

class DialogButton extends Widget with Hoverable, HoverAnimated {
  String label;
  Color textColor;
  Color backgroundColor;
  Color hoverColor;
  VoidCallback? onPressed;

  DialogButton(
    this.label, {
    this.textColor = const Color(255, 255, 255),
    this.backgroundColor = const Color(55, 55, 55),
    this.hoverColor = const Color(80, 80, 80),
    this.onPressed,
  }) : assert(label.isNotEmpty, 'DialogButton label must not be empty') {
    width = label.length * 8 + 16;
    height = 24;
    onClick = () {
      onPressed?.call();
      return true;
    };
  }

  @override
  bool get acceptsFocus => true;

  @override
  Style styleRole() => Style(
    color: textColor,
    backgroundColor: backgroundColor,
    borderColor: backgroundColor,
    borderWidth: 0,
  );

  @override
  void draw(Painter canvas) {
    final base = resolvedStyle();
    final hover = resolvedStyleOn(const [
      'hover',
    ], local: StylePatch(backgroundColor: hoverColor));
    final fill = transitionHover(base.backgroundColor!, hover.backgroundColor!);
    drawStyledBox(
      canvas,
      style: base.overlay(StylePatch(backgroundColor: fill)),
    );
    drawStyledText(
      canvas,
      label,
      Offset(
        (x + (width - label.length * 8) ~/ 2).toDouble(),
        (y + styledPaddingTop(4)).toDouble(),
      ),
      fallback: const Font(pixelSize: 16),
      color: base.color,
      style: base,
    );
  }
}

class Dialog extends Widget {
  String? title;
  String message;
  List<DialogButton> buttons;
  Color backgroundColor;
  Color borderColor;
  Color titleColor;
  Color textColor;
  int titleBarHeight;
  int padding;

  Dialog({
    this.title,
    required this.message,
    this.buttons = const [],
    this.backgroundColor = const Color(36, 36, 36),
    this.borderColor = const Color(80, 80, 80),
    this.titleColor = const Color(255, 255, 255),
    this.textColor = const Color(200, 200, 200),
    this.titleBarHeight = 30,
    this.padding = 16,
  }) : assert(padding >= 0, 'Dialog padding must be >= 0') {
    width = 300;
    final msgLines = (message.length / 40).ceil().clamp(1, 4);
    height = titleBarHeight + padding * 2 + msgLines * 20 + 40;
  }

  @override
  Style styleRole() => Style(
    color: textColor,
    backgroundColor: backgroundColor,
    borderColor: borderColor,
  );

  @override
  void draw(Painter canvas) {
    final style = resolvedStyle();
    final padL = styledPaddingLeft(padding);
    final padR = styledPaddingRight(padding);
    final padT = styledPaddingTop(padding);
    final padB = styledPaddingBottom(padding);
    drawStyledBox(canvas, style: style);

    if (title != null) {
      canvas.drawRect(
        Rect.fromLTWH(
          (x + 1).toDouble(),
          (y + 1).toDouble(),
          (width - 2).toDouble(),
          titleBarHeight.toDouble(),
        ),
        Paint()..color = style.backgroundColor ?? const Color(45, 45, 45),
      );
      drawStyledText(
        canvas,
        title!,
        Offset(
          (x + padL).toDouble(),
          (y + (titleBarHeight - 16) ~/ 2).toDouble(),
        ),
        style: style,
        color: style.color,
        fallback: const Font(pixelSize: 16),
      );
    }

    final textY = y + (title != null ? titleBarHeight + padT : padT);
    drawStyledText(
      canvas,
      message,
      Offset((x + padL).toDouble(), textY.toDouble()),
      style: style,
      color: style.color,
      fallback: const Font(pixelSize: 16),
    );

    var bx = x + width - padR;
    for (final btn in buttons.reversed) {
      bx -= btn.width + 8;
      btn.x = bx;
      btn.y = y + height - padB - btn.height;
      btn.draw(canvas);
    }
  }

  @override
  bool hitTest(int px, int py) {
    if (!super.hitTest(px, py)) return false;
    for (final btn in buttons.reversed) {
      if (btn.hitTest(px, py)) return true;
    }
    return false;
  }
}
