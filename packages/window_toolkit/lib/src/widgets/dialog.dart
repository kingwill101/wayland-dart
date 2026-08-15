import '../drawing/color.dart';
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
    canvas.drawText(
      label,
      Offset(
        (x + (width - label.length * 8) ~/ 2).toDouble(),
        (y + 4).toDouble(),
      ),
      color: base.color,
      size: 16,
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
    canvas.drawRect(
      Rect.fromLTWH(
        x.toDouble(),
        y.toDouble(),
        width.toDouble(),
        height.toDouble(),
      ),
      Paint()..color = style.backgroundColor!,
    );

    // Border
    canvas.drawRect(
      Rect.fromLTWH(x.toDouble(), y.toDouble(), width.toDouble(), 1),
      Paint()..color = style.borderColor,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        x.toDouble(),
        (y + height - 1).toDouble(),
        width.toDouble(),
        1,
      ),
      Paint()..color = style.borderColor,
    );
    canvas.drawRect(
      Rect.fromLTWH(x.toDouble(), y.toDouble(), 1, height.toDouble()),
      Paint()..color = style.borderColor,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        (x + width - 1).toDouble(),
        y.toDouble(),
        1,
        height.toDouble(),
      ),
      Paint()..color = style.borderColor,
    );

    if (title != null) {
      canvas.drawRect(
        Rect.fromLTWH(
          (x + 1).toDouble(),
          (y + 1).toDouble(),
          (width - 2).toDouble(),
          titleBarHeight.toDouble(),
        ),
        Paint()..color = const Color(45, 45, 45),
      );
      canvas.drawText(
        title!,
        Offset(
          (x + padding).toDouble(),
          (y + (titleBarHeight - 16) ~/ 2).toDouble(),
        ),
        color: style.color,
        size: 16,
      );
    }

    final textY = y + (title != null ? titleBarHeight + padding : padding);
    canvas.drawText(
      message,
      Offset((x + padding).toDouble(), textY.toDouble()),
      color: style.color,
      size: 16,
    );

    var bx = x + width - padding;
    for (final btn in buttons.reversed) {
      bx -= btn.width + 8;
      btn.x = bx;
      btn.y = y + height - padding - btn.height;
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
