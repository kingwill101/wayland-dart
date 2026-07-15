import '../drawing/color.dart';
import '../metrics.dart';
import '../painter/painter.dart';
import '../widget.dart';

/// Draws a background (and optional border / rounded corners) behind [child].
class DecoratedBox extends Widget {
  final Widget? child;
  Color? color;
  Color? borderColor;
  double borderWidth;
  double borderRadius;
  int padding;

  DecoratedBox({
    this.child,
    this.color,
    this.borderColor,
    this.borderWidth = 0,
    double? borderRadius,
    this.padding = 0,
  })  : assert(borderWidth >= 0, 'DecoratedBox borderWidth must be >= 0'),
        assert(padding >= 0, 'DecoratedBox padding must be >= 0'),
        borderRadius = borderRadius ?? ThemeMetrics.current.borderRadiusSm;

  @override
  void measure(Painter painter) {
    child?.measure(painter);
    final cw = child?.width ?? 0;
    final ch = child?.height ?? 0;
    width = cw + padding * 2;
    height = ch + padding * 2;
  }

  @override
  void performLayout(int containerWidth) {
    width = containerWidth;
    final inner = (width - padding * 2).clamp(0, width);
    if (child != null) {
      child!.performLayout(inner);
      height = child!.height + padding * 2;
    }
  }

  @override
  void draw(Painter canvas) {
    final rect = Rect.fromLTWH(
      x.toDouble(),
      y.toDouble(),
      width.toDouble(),
      height.toDouble(),
    );
    if (color != null) {
      if (borderRadius > 0) {
        canvas.drawRRect(rect, borderRadius, borderRadius, Paint()..color = color!);
      } else {
        canvas.drawRect(rect, Paint()..color = color!);
      }
    }
    if (borderColor != null && borderWidth > 0) {
      final borderPaint = Paint()
        ..color = borderColor!
        ..style = PaintStyle.stroke
        ..strokeWidth = borderWidth;
      if (borderRadius > 0) {
        canvas.drawRRect(
          Rect.fromLTWH(
            x + borderWidth / 2,
            y + borderWidth / 2,
            width - borderWidth,
            height - borderWidth,
          ),
          borderRadius,
          borderRadius,
          borderPaint,
        );
      } else {
        canvas.drawRect(
          Rect.fromLTWH(
            x + borderWidth / 2,
            y + borderWidth / 2,
            width - borderWidth,
            height - borderWidth,
          ),
          borderPaint,
        );
      }
    }
    if (child != null) {
      child!
        ..x = x + padding
        ..y = y + padding
        ..width = (width - padding * 2).clamp(0, width)
        ..height = (height - padding * 2).clamp(0, height);
      child!.draw(canvas);
    }
  }

  @override
  bool hitTest(int px, int py) {
    if (!super.hitTest(px, py)) return false;
    if (child == null) return true;
    child!
      ..x = x + padding
      ..y = y + padding;
    return child!.hitTest(px, py) || true;
  }
}
