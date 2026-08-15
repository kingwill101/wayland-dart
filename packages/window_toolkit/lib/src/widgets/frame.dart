import '../drawing/color.dart';
import '../painter/painter.dart';
import '../style.dart';
import '../widget.dart';

class Frame extends Widget {
  @override
  Color color;
  int borderWidth;
  Color? borderColor;
  @override
  List<Widget> children;

  Frame({
    this.color = const Color(0, 0, 0, 0),
    this.borderWidth = 0,
    this.borderColor,
    List<Widget>? children,
  }) : assert(borderWidth >= 0, 'Frame borderWidth must be >= 0'),
       children = children ?? [];

  @override
  Style styleRole() => Style(
    color: palette.text,
    backgroundColor: color,
    borderColor: borderColor ?? palette.mid,
    borderWidth: borderWidth.toDouble(),
  );

  @override
  void performLayout(int containerWidth) {
    width = containerWidth;
    var maxH = 0;
    for (final child in children) {
      child.performLayout(width);
      final childBottom = child.y + child.height;
      if (childBottom > maxH) maxH = childBottom;
    }
    height = maxH;
  }

  @override
  void draw(Painter canvas) {
    final style = resolvedStyle();
    drawStyledBox(canvas, style: style);

    for (final child in children) {
      child.draw(canvas);
    }
  }

  @override
  bool hitTest(int px, int py) {
    if (!super.hitTest(px, py)) return false;
    for (final child in children) {
      if (child.hitTest(px, py)) return true;
    }
    return false;
  }
}
