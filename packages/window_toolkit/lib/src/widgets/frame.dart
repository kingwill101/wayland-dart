import '../drawing/color.dart';
import '../painter/painter.dart';
import '../widget.dart';

class Frame extends Widget {
  @override

  Color color;
  int borderWidth;
  Color? borderColor;
  List<Widget> children;

  Frame({
    this.color = const Color(0, 0, 0, 0),
    this.borderWidth = 0,
    this.borderColor,
    List<Widget>? children,
  }) : children = children ?? [];

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
    if (color.a > 0) {
      canvas.drawRect(
          Rect.fromLTWH(x.toDouble(), y.toDouble(), width.toDouble(),
              height.toDouble()),
          Paint()..color = color);
    }

    final bc = borderColor;
    if (borderWidth > 0 && bc != null) {
      canvas.drawRect(
          Rect.fromLTWH(x.toDouble(), y.toDouble(), width.toDouble(),
              borderWidth.toDouble()),
          Paint()..color = bc);
      canvas.drawRect(
          Rect.fromLTWH(x.toDouble(), (y + height - borderWidth).toDouble(),
              width.toDouble(), borderWidth.toDouble()),
          Paint()..color = bc);
      canvas.drawRect(
          Rect.fromLTWH(x.toDouble(), y.toDouble(), borderWidth.toDouble(),
              height.toDouble()),
          Paint()..color = bc);
      canvas.drawRect(
          Rect.fromLTWH((x + width - borderWidth).toDouble(), y.toDouble(),
              borderWidth.toDouble(), height.toDouble()),
          Paint()..color = bc);
    }

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

