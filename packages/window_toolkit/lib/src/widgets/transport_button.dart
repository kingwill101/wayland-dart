import '../drawing/color.dart';
import '../interaction.dart';
import '../mixins/hover_animated.dart';
import '../mixins/hoverable.dart';
import '../painter/painter.dart';
import '../style.dart';
import '../style/style_patch.dart';
import '../widget.dart';

/// Vector media-control glyphs that do not depend on an icon font.
enum TransportAction { previous, play, pause, next }

/// A focusable, hover-animated media transport control.
class TransportButton extends Widget with Hoverable, HoverAnimated {
  TransportAction action;
  Color backgroundColor;
  Color hoverColor;
  Color iconColor;
  VoidCallback? onPressed;

  TransportButton(
    this.action, {
    this.backgroundColor = const Color(70, 78, 90),
    this.hoverColor = const Color(96, 106, 122),
    this.iconColor = const Color(240, 240, 245),
    this.onPressed,
    int size = 44,
  }) {
    width = size;
    height = 30;
    tabIndex = 1;
    onClick = () {
      onPressed?.call();
      return true;
    };
  }

  @override
  bool get acceptsFocus => true;

  @override
  Style styleRole() => Style(
    color: iconColor,
    backgroundColor: backgroundColor,
    borderColor: backgroundColor,
    borderWidth: 0,
    borderRadius: 7,
  );

  @override
  void onFocusChanged(bool focused) {
    setInteractionState(WidgetState.focused, focused);
  }

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

    final cx = x + width / 2;
    final cy = y + height / 2;
    final ink = Paint()
      ..color = styledColor(base.color, base)
      ..strokeWidth = 2;
    switch (action) {
      case TransportAction.previous:
        canvas.drawLine(Offset(cx - 8, cy - 7), Offset(cx - 8, cy + 7), ink);
        canvas.drawLine(Offset(cx + 7, cy - 7), Offset(cx - 2, cy), ink);
        canvas.drawLine(Offset(cx - 2, cy), Offset(cx + 7, cy + 7), ink);
      case TransportAction.next:
        canvas.drawLine(Offset(cx + 8, cy - 7), Offset(cx + 8, cy + 7), ink);
        canvas.drawLine(Offset(cx - 7, cy - 7), Offset(cx + 2, cy), ink);
        canvas.drawLine(Offset(cx + 2, cy), Offset(cx - 7, cy + 7), ink);
      case TransportAction.pause:
        canvas.drawRect(
          Rect.fromLTWH(cx - 6, cy - 7, 4, 14),
          Paint()..color = styledColor(base.color, base),
        );
        canvas.drawRect(
          Rect.fromLTWH(cx + 2, cy - 7, 4, 14),
          Paint()..color = styledColor(base.color, base),
        );
      case TransportAction.play:
        canvas.drawLine(Offset(cx - 5, cy - 8), Offset(cx + 7, cy), ink);
        canvas.drawLine(Offset(cx + 7, cy), Offset(cx - 5, cy + 8), ink);
        canvas.drawLine(Offset(cx - 5, cy + 8), Offset(cx - 5, cy - 8), ink);
    }
  }
}
