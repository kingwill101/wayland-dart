import '../drawing/color.dart';
import '../painter/painter.dart';
import '../widget.dart';

class Button extends Widget {
  String text;
  Color? _textColor;
  Color? _backgroundColor;
  Color? _hoverColor;
  bool _hovered = false;
  final int padding;
  final int charWidth;
  final int charHeight;

  Button(
    this.text, {
    Color? textColor,
    Color? backgroundColor,
    Color? hoverColor,
    VoidCallback? onPressed,
    this.padding = 4,
    this.charWidth = 8,
    this.charHeight = 16,
  })  : assert(text.isNotEmpty, 'Button text must not be empty'),
        assert(padding >= 0, 'Button padding must be >= 0'),
        assert(charWidth > 0 && charHeight > 0, 'Button charWidth/charHeight must be > 0'),
        _textColor = textColor,
        _backgroundColor = backgroundColor,
        _hoverColor = hoverColor {
    width = text.length * charWidth + padding * 2;
    height = charHeight + padding * 2;
    tabIndex = 1;
    onClick = onPressed;
    onMouseEnter = () => _hovered = true;
    onMouseLeave = () => _hovered = false;
  }

  @override
  bool get acceptsFocus => true;

  @override
  void onFocusChanged(bool focused) {
    _hovered = focused;
  }

  Color get textColor => _textColor ?? palette.buttonText;
  Color get backgroundColor => _backgroundColor ?? palette.button;
  Color get hoverColor => _hoverColor ?? palette.midlight;

  @override
  void measure(Painter painter) {
    final tw = painter.measureText(text, size: charHeight.toDouble()).width;
    width = (tw.round() + padding * 2).clamp(charHeight + padding, 400);
    height = charHeight + padding * 2;
  }

  @override
  void draw(Painter canvas) {
    final c = _hovered ? hoverColor : backgroundColor;
    canvas.drawRect(
      Rect.fromLTWH(
        x.toDouble(),
        y.toDouble(),
        width.toDouble(),
        height.toDouble(),
      ),
      Paint()..color = c,
    );
    final tw = canvas.measureText(text, size: charHeight.toDouble()).width;
    final tx = x + (width - tw) / 2;
    final ty = y + padding.toDouble();
    canvas.drawText(
      text,
      Offset(tx, ty),
      size: charHeight.toDouble(),
      color: textColor,
    );
  }
}
