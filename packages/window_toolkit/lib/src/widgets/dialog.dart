import '../drawing/color.dart';
import '../painter/painter.dart';
import '../widget.dart';

class DialogButton extends Widget {
  String label;
  Color textColor;
  Color backgroundColor;
  Color hoverColor;
  VoidCallback? onPressed;

  bool _hovered = false;

  DialogButton(
    this.label, {
    this.textColor = const Color(255, 255, 255),
    this.backgroundColor = const Color(55, 55, 55),
    this.hoverColor = const Color(80, 80, 80),
    this.onPressed,
  })  : assert(label.isNotEmpty, 'DialogButton label must not be empty') {
    width = label.length * 8 + 16;
    height = 24;
    onMouseEnter = () => _hovered = true;
    onMouseLeave = () => _hovered = false;
    onClick = () { onPressed?.call(); return true; };
  }

  @override
  void draw(Painter canvas) {
    final fill = _hovered ? hoverColor : backgroundColor;
    canvas.drawRect(
      Rect.fromLTWH(x.toDouble(), y.toDouble(), width.toDouble(), height.toDouble()),
      Paint()..color = fill,
    );
    canvas.drawText(
      label,
      Offset(
        (x + (width - label.length * 8) ~/ 2).toDouble(),
        (y + 4).toDouble(),
      ),
      color: textColor,
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
  })  : assert(padding >= 0, 'Dialog padding must be >= 0') {
    width = 300;
    final msgLines = (message.length / 40).ceil().clamp(1, 4);
    height = titleBarHeight + padding * 2 + msgLines * 20 + 40;
  }

  @override
  void draw(Painter canvas) {
    canvas.drawRect(
      Rect.fromLTWH(x.toDouble(), y.toDouble(), width.toDouble(), height.toDouble()),
      Paint()..color = backgroundColor,
    );

    // Border
    canvas.drawRect(
      Rect.fromLTWH(x.toDouble(), y.toDouble(), width.toDouble(), 1),
      Paint()..color = borderColor,
    );
    canvas.drawRect(
      Rect.fromLTWH(x.toDouble(), (y + height - 1).toDouble(), width.toDouble(), 1),
      Paint()..color = borderColor,
    );
    canvas.drawRect(
      Rect.fromLTWH(x.toDouble(), y.toDouble(), 1, height.toDouble()),
      Paint()..color = borderColor,
    );
    canvas.drawRect(
      Rect.fromLTWH((x + width - 1).toDouble(), y.toDouble(), 1, height.toDouble()),
      Paint()..color = borderColor,
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
        Offset((x + padding).toDouble(), (y + (titleBarHeight - 16) ~/ 2).toDouble()),
        color: titleColor,
        size: 16,
      );
    }

    final textY = y + (title != null ? titleBarHeight + padding : padding);
    canvas.drawText(
      message,
      Offset((x + padding).toDouble(), textY.toDouble()),
      color: textColor,
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
