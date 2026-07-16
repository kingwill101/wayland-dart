import '../drawing/color.dart';
import '../painter/painter.dart';
import '../widget.dart';

class MenuItem extends Widget {
  String label;
  Color textColor;
  Color backgroundColor;
  Color hoverColor;
  int itemHeight;
  VoidCallback? onTriggered;

  bool _hovered = false;

  MenuItem(
    this.label, {
    this.textColor = const Color(255, 255, 255),
    this.backgroundColor = const Color(36, 36, 36),
    this.hoverColor = const Color(55, 55, 55),
    this.itemHeight = 24,
    this.onTriggered,
  })  : assert(itemHeight > 0, 'MenuItem itemHeight must be > 0') {
    width = label.length * 8 + 24;
    height = itemHeight;
    onMouseEnter = () => setState(() => _hovered = true);
    onMouseLeave = () => setState(() => _hovered = false);
    onClick = () { onTriggered?.call(); return true; };
  }

  @override
  void draw(Painter canvas) {
    final fill = _hovered ? hoverColor : backgroundColor;
    canvas.drawRect(
      Rect.fromLTWH(x.toDouble(), y.toDouble(), width.toDouble(), height.toDouble()),
      Paint()..color = fill,
    );

    canvas.drawText(
      label,
      Offset((x + 12).toDouble(), (y + (itemHeight - 16) ~/ 2).toDouble()),
      color: textColor,
      size: 16,
    );
  }
}

class Menu extends Widget {
  List<MenuItem> items;
  Color borderColor;
  int padding;

  Menu({
    required this.items,
    this.borderColor = const Color(70, 70, 70),
    this.padding = 4,
  }) {
    var maxW = 0;
    var totalH = padding * 2;
    for (final item in items) {
      if (item.width > maxW) maxW = item.width;
      totalH += item.height;
    }
    width = maxW + padding * 2;
    height = totalH;
  }

  @override
  void draw(Painter canvas) {
    canvas.drawRect(
      Rect.fromLTWH(x.toDouble(), y.toDouble(), width.toDouble(), height.toDouble()),
      Paint()..color = const Color(36, 36, 36),
    );

    canvas.drawRect(
      Rect.fromLTWH(x.toDouble(), y.toDouble(), width.toDouble(), 1),
      Paint()..color = borderColor,
    );
    canvas.drawRect(
      Rect.fromLTWH(x.toDouble(), (y + height - 1).toDouble(), width.toDouble(), 1),
      Paint()..color = borderColor,
    );
    canvas.drawRect(
      Rect.fromLTWH(x.toDouble(), y.toDouble(), 1, height.toDouble()),
      Paint()..color = borderColor,
    );
    canvas.drawRect(
      Rect.fromLTWH((x + width - 1).toDouble(), y.toDouble(), 1, height.toDouble()),
      Paint()..color = borderColor,
    );

    var cy = y + padding;
    for (final item in items) {
      item.x = x + padding;
      item.y = cy;
      item.width = width - padding * 2;
      item.draw(canvas);
      cy += item.height;
    }
  }

  @override
  bool hitTest(int px, int py) {
    if (!super.hitTest(px, py)) return false;
    for (final item in items.reversed) {
      if (item.hitTest(px, py)) return true;
    }
    return false;
  }

  int itemAt(int px, int py) {
    for (var i = 0; i < items.length; i++) {
      if (items[i].hitTest(px, py)) return i;
    }
    return -1;
  }
}
