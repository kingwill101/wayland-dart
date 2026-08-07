
import '../drawing/color.dart';
import '../painter/painter.dart';
import '../style/style_context.dart';
import '../widget.dart';

class Button extends Widget {
  String text;
  final Color? _textColor;
  final Color? _backgroundColor;
  final Color? _hoverColor;
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
    super.key,
  })  : assert(text.isNotEmpty, 'Button text must not be empty'),
        assert(padding >= 0, 'Button padding must be >= 0'),
        assert(charWidth > 0 && charHeight > 0, 'Button charWidth/charHeight must be > 0'),
        _textColor = textColor,
        _backgroundColor = backgroundColor,
        _hoverColor = hoverColor {
    width = text.length * charWidth + padding * 2;
    height = charHeight + padding * 2;
    tabIndex = 1;
    onClick = () { onPressed?.call(); return true; };
    onMouseEnter = () {
      addPseudoClass('hover');
      setState(() => _hovered = true);
    };
    onMouseLeave = () {
      removePseudoClass('hover');
      setState(() => _hovered = false);
    };
  }

  @override
  bool get acceptsFocus => true;

  @override
  void onFocusChanged(bool focused) {
    setState(() => _hovered = focused);
  }

  Color get textColor => _textColor ?? palette.buttonText;
  Color get backgroundColor => _backgroundColor ?? palette.button;
  Color get hoverColor => _hoverColor ?? palette.midlight;

  @override
  void performLayout(int containerWidth) {
    final intrinsic = text.length * charWidth + padding * 2;
    if (containerWidth > 0 && containerWidth < intrinsic) {
      width = containerWidth;
    } else {
      width = intrinsic;
    }
    height = charHeight + padding * 2;
  }

  @override
  void measure(Painter painter) {
    final tw = painter.measureText(text, size: charHeight.toDouble()).width;
    width = (tw.round() + padding * 2).clamp(charHeight + padding, 400);
    height = charHeight + padding * 2;
  }

  @override
  void draw(Painter canvas) {
    // GTK-like: let CSS override hardcoded colors (waybar #workspaces button.active)
    final ctx = StyleContext.forWidget(this);
    final styleBg = ctx.parsedBackgroundColor;
    final styleHoverBg = StyleContext.forWidget(this..addPseudoClass('hover')).parsedBackgroundColor;
    // Reset temporary hover addition if not actually hovered
    if (!_hovered) removePseudoClass('hover');
    final c = _hovered
        ? (styleHoverBg ?? hoverColor)
        : (styleBg ?? backgroundColor);
    final styleFg = ctx.parsedColor;
    final fg = styleFg ?? textColor;
    // Background via CSS or fallback
    if (styleBg != null || _backgroundColor != null) {
      canvas.drawRect(
        Rect.fromLTWH(
          x.toDouble(),
          y.toDouble(),
          width.toDouble(),
          height.toDouble(),
        ),
        Paint()..color = c,
      );
    } else {
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
    final tw = canvas.measureText(text, size: charHeight.toDouble()).width;
    final tx = x + (width - tw) / 2;
    final ty = y + padding.toDouble();
    canvas.drawText(
      text,
      Offset(tx, ty),
      size: charHeight.toDouble(),
      color: fg,
    );
    // Border from CSS if present
    final border = ctx.parsedBorderColor;
    if (border != null) {
      canvas.drawRect(
        Rect.fromLTWH(x.toDouble(), y.toDouble(), width.toDouble(), height.toDouble()),
        Paint()
          ..color = border
          ..style = PaintStyle.stroke
          ..strokeWidth = 1,
      );
    }
  }
}
