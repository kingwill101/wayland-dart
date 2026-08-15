import '../drawing/color.dart';
import '../painter/painter.dart';
import '../widget.dart';

class GroupBox extends Widget {
  @override
  String? title;
  @override
  List<Widget> children;
  Color backgroundColor;
  Color borderColor;
  Color titleColor;
  Color titleBg;
  int borderWidth;
  int padding;
  int spacing;
  int titleHeight;

  GroupBox({
    this.title,
    this.children = const <Widget>[],
    this.backgroundColor = const Color(28, 28, 28),
    this.borderColor = const Color(80, 80, 80),
    this.titleColor = const Color(200, 200, 200),
    this.titleBg = const Color(28, 28, 28),
    this.borderWidth = 1,
    this.padding = 12,
    this.spacing = 8,
    this.titleHeight = 22,
  }) : assert(borderWidth >= 0, 'GroupBox borderWidth must be >= 0'),
       assert(padding >= 0, 'GroupBox padding must be >= 0'),
       assert(spacing >= 0, 'GroupBox spacing must be >= 0');

  int get _titleOffset => title == null ? 0 : titleHeight;

  @override
  void performLayout(int containerWidth) {
    width = containerWidth;
    var cy = padding + _titleOffset;
    for (final child in children) {
      child.performLayout((width - padding * 2).clamp(0, width).toInt());
      cy += child.height + spacing;
    }
    if (children.isNotEmpty) cy -= spacing;
    height = cy + padding;
  }

  @override
  void draw(Painter canvas) {
    performLayout(width);

    canvas.drawRect(
      Rect.fromLTWH(
        x.toDouble(),
        y.toDouble(),
        width.toDouble(),
        height.toDouble(),
      ),
      Paint()..color = backgroundColor,
    );

    // Border
    if (borderWidth > 0) {
      canvas.drawRect(
        Rect.fromLTWH(
          x.toDouble(),
          y.toDouble(),
          width.toDouble(),
          borderWidth.toDouble(),
        ),
        Paint()..color = borderColor,
      );
      canvas.drawRect(
        Rect.fromLTWH(
          x.toDouble(),
          (y + height - borderWidth).toDouble(),
          width.toDouble(),
          borderWidth.toDouble(),
        ),
        Paint()..color = borderColor,
      );
      canvas.drawRect(
        Rect.fromLTWH(
          x.toDouble(),
          y.toDouble(),
          borderWidth.toDouble(),
          height.toDouble(),
        ),
        Paint()..color = borderColor,
      );
      canvas.drawRect(
        Rect.fromLTWH(
          (x + width - borderWidth).toDouble(),
          y.toDouble(),
          borderWidth.toDouble(),
          height.toDouble(),
        ),
        Paint()..color = borderColor,
      );
    }

    // Title
    if (title != null) {
      final titleW = title!.length * 8 + 8;
      final titleX = x + padding;
      canvas.drawRect(
        Rect.fromLTWH(
          titleX.toDouble(),
          y.toDouble(),
          titleW.toDouble(),
          titleHeight.toDouble(),
        ),
        Paint()..color = titleBg,
      );
      canvas.drawText(
        title!,
        Offset(
          (titleX + 4).toDouble(),
          (y + (titleHeight - 16) ~/ 2).toDouble(),
        ),
        color: titleColor,
        size: 16,
      );
    }

    // Children
    var cy = y + padding + _titleOffset;
    for (final child in children) {
      child.x = x + padding;
      child.y = cy;
      child.width = (width - padding * 2).clamp(0, width).toInt();
      child.draw(canvas);
      cy += child.height + spacing;
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
