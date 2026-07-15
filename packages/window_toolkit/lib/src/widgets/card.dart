import '../drawing/color.dart';
import '../painter/painter.dart';
import '../widget.dart';

class Card extends Widget {
  String? title;
  List<Widget> children;
  Color backgroundColor;
  Color borderColor;
  int borderWidth;
  int padding;
  int spacing;
  Color titleColor;

  Card({
    this.title,
    List<Widget>? children,
    this.backgroundColor = const Color(28, 28, 28),
    this.borderColor = const Color(90, 90, 90),
    this.borderWidth = 1,
    this.padding = 12,
    this.spacing = 8,
    this.titleColor = const Color(255, 255, 255),
  }) : children = children ?? [];

  @override
  void performLayout(int containerWidth) {
    width = containerWidth;
    var totalH = padding + (title == null ? 0 : 22);
    for (final child in children) {
      child.performLayout((width - padding * 2).clamp(0, width).toInt());
      totalH += child.height + spacing;
    }
    if (children.isNotEmpty) totalH -= spacing;
    height = totalH + padding;
  }

  void layoutChildren() {
    var cy = y + padding + (title == null ? 0 : 22);
    for (final child in children) {
      child.x = x + padding;
      child.y = cy;
      child.width = (width - padding * 2).clamp(0, width).toInt();
      cy += child.height + spacing;
    }
  }

  @override
  void draw(Painter canvas) {
    layoutChildren();

    canvas.drawRect(
      Rect.fromLTWH(x.toDouble(), y.toDouble(), width.toDouble(), height.toDouble()),
      Paint()..color = backgroundColor,
    );

    if (borderWidth > 0) {
      canvas.drawRect(
        Rect.fromLTWH(x.toDouble(), y.toDouble(), width.toDouble(), borderWidth.toDouble()),
        Paint()..color = borderColor,
      );
      canvas.drawRect(
        Rect.fromLTWH(x.toDouble(), (y + height - borderWidth).toDouble(), width.toDouble(), borderWidth.toDouble()),
        Paint()..color = borderColor,
      );
      canvas.drawRect(
        Rect.fromLTWH(x.toDouble(), y.toDouble(), borderWidth.toDouble(), height.toDouble()),
        Paint()..color = borderColor,
      );
      canvas.drawRect(
        Rect.fromLTWH((x + width - borderWidth).toDouble(), y.toDouble(), borderWidth.toDouble(), height.toDouble()),
        Paint()..color = borderColor,
      );
    }

    if (title != null) {
      canvas.drawText(
        title!,
        Offset((x + padding).toDouble(), (y + padding).toDouble()),
        color: titleColor,
        size: 16,
      );
    }

    for (final child in children) {
      child.draw(canvas);
    }
  }

  @override
  bool hitTest(int px, int py) {
    layoutChildren();
    if (!super.hitTest(px, py)) return false;
    for (final child in children) {
      if (child.hitTest(px, py)) return true;
    }
    return false;
  }
}
