import '../drawing/color.dart';
import '../painter/painter.dart';
import '../style.dart';
import '../widget.dart';

class Card extends Widget {
  @override
  String? title;
  @override
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
  Style styleRole() => Style(
    color: titleColor,
    backgroundColor: backgroundColor,
    borderColor: borderColor,
    borderWidth: borderWidth.toDouble(),
  );

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
    final style = resolvedStyle();
    final border = style.borderWidth.round();

    canvas.drawRect(
      Rect.fromLTWH(
        x.toDouble(),
        y.toDouble(),
        width.toDouble(),
        height.toDouble(),
      ),
      Paint()..color = style.backgroundColor!,
    );

    if (border > 0) {
      canvas.drawRect(
        Rect.fromLTWH(
          x.toDouble(),
          y.toDouble(),
          width.toDouble(),
          border.toDouble(),
        ),
        Paint()..color = style.borderColor,
      );
      canvas.drawRect(
        Rect.fromLTWH(
          x.toDouble(),
          (y + height - border).toDouble(),
          width.toDouble(),
          border.toDouble(),
        ),
        Paint()..color = style.borderColor,
      );
      canvas.drawRect(
        Rect.fromLTWH(
          x.toDouble(),
          y.toDouble(),
          border.toDouble(),
          height.toDouble(),
        ),
        Paint()..color = style.borderColor,
      );
      canvas.drawRect(
        Rect.fromLTWH(
          (x + width - border).toDouble(),
          y.toDouble(),
          border.toDouble(),
          height.toDouble(),
        ),
        Paint()..color = style.borderColor,
      );
    }

    if (title != null) {
      canvas.drawText(
        title!,
        Offset((x + padding).toDouble(), (y + padding).toDouble()),
        color: style.color,
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
