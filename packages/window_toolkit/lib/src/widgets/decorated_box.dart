import '../drawing/color.dart';
import '../metrics.dart';
import '../painter/painter.dart';
import '../style.dart';
import '../style/style_patch.dart';
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
  }) : assert(borderWidth >= 0, 'DecoratedBox borderWidth must be >= 0'),
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

  /// DecoratedBox role: transparent background, no border by default; only an
  /// explicit background / CSS / local values produce a filled or bordered box.
  @override
  Style styleRole() => Style(
    color: palette.text,
    backgroundColor: const Color(0, 0, 0, 0),
    borderColor: palette.mid,
    borderWidth: 0,
    borderRadius: ThemeMetrics.current.borderRadiusSm.toDouble(),
  );

  /// The box's own explicit fields fold into the single cascade.
  @override
  StylePatch localOverrides() => StylePatch(
    backgroundColor: color,
    borderTopColor: borderColor,
    borderRightColor: borderColor,
    borderBottomColor: borderColor,
    borderLeftColor: borderColor,
    borderTopWidth: borderWidth,
    borderRightWidth: borderWidth,
    borderBottomWidth: borderWidth,
    borderLeftWidth: borderWidth,
    borderTopLeftRadius: borderRadius,
    borderTopRightRadius: borderRadius,
    borderBottomRightRadius: borderRadius,
    borderBottomLeftRadius: borderRadius,
  );

  @override
  void draw(Painter canvas) {
    // CSS (style system) overrides explicit / theme values, centrally.
    final st = resolvedStyle();
    drawStyledBox(canvas, style: st);
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
