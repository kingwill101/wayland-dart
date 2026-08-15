import '../drawing/color.dart';
import '../metrics.dart';
import '../interaction.dart';
import '../mixins/hoverable.dart';
import '../mixins/hover_animated.dart';
import '../painter/painter.dart';
import '../style.dart';
import '../style/style_patch.dart';
import '../widget.dart';

class Button extends Widget with Hoverable, HoverAnimated {
  String text;
  final Color? _textColor;
  final Color? _backgroundColor;
  final Color? _hoverColor;
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
  }) : assert(text.isNotEmpty, 'Button text must not be empty'),
       assert(padding >= 0, 'Button padding must be >= 0'),
       assert(
         charWidth > 0 && charHeight > 0,
         'Button charWidth/charHeight must be > 0',
       ),
       _textColor = textColor,
       _backgroundColor = backgroundColor,
       _hoverColor = hoverColor {
    width = text.length * charWidth + padding * 2;
    height = charHeight + padding * 2;
    tabIndex = 1;
    onClick = () {
      onPressed?.call();
      return true;
    };
  }

  @override
  bool get acceptsFocus => true;

  @override
  void onFocusChanged(bool focused) {
    setInteractionState(WidgetState.focused, focused);
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

  /// Button roles: button-text / button face / no default border (only CSS or
  /// an explicit border via `localOverrides` enables one).
  @override
  Style styleRole() => Style(
    color: palette.buttonText,
    backgroundColor: palette.button,
    borderColor: palette.mid,
    borderWidth: 0,
    borderRadius: ThemeMetrics.current.borderRadiusSm.toDouble(),
    fontSize: ThemeMetrics.current.fontSize,
  );

  /// The button's own constructor colors; the hover face flows through
  /// [`resolvedStyleOn`('hover')`] instead.
  @override
  StylePatch localOverrides() =>
      StylePatch(color: _textColor, backgroundColor: _backgroundColor);

  @override
  void draw(Painter canvas) {
    // Single cascade point (StyleContext.resolveStyle) → concrete values.
    final base = resolvedStyle();
    final hover = resolvedStyleOn(const [
      'hover',
    ], local: StylePatch(backgroundColor: _hoverColor ?? palette.midlight));
    final c = transitionHover(base.backgroundColor!, hover.backgroundColor!);
    final fg = base.color;

    final rect = Rect.fromLTWH(
      x.toDouble(),
      y.toDouble(),
      width.toDouble(),
      height.toDouble(),
    );
    if (base.borderRadius > 0) {
      canvas.drawRRect(
        rect,
        base.borderRadius,
        base.borderRadius,
        Paint()..color = c,
      );
    } else {
      canvas.drawRect(rect, Paint()..color = c);
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
    // Border when a width is in effect (CSS-provided or explicit).
    if (base.borderWidth > 0) {
      final borderPaint = Paint()
        ..color = base.borderColor
        ..style = PaintStyle.stroke
        ..strokeWidth = base.borderWidth;
      if (base.borderRadius > 0) {
        canvas.drawRRect(
          Rect.fromLTWH(
            x + base.borderWidth / 2,
            y + base.borderWidth / 2,
            width - base.borderWidth,
            height - base.borderWidth,
          ),
          base.borderRadius,
          base.borderRadius,
          borderPaint,
        );
      } else {
        canvas.drawRect(rect, borderPaint);
      }
    }
  }
}
