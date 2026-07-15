import '../painter/painter.dart';
import '../widget.dart';
import 'menu.dart';

class ContextMenu extends Widget {
  List<MenuItem> items;
  bool visible;
  int targetX;
  int targetY;

  ContextMenu({
    this.items = const [],
    this.visible = false,
    this.targetX = 0,
    this.targetY = 0,
  });

  @override
  void draw(Painter canvas) {
    if (!visible || items.isEmpty) return;
    final menu = Menu(items: items);
    menu.x = targetX;
    menu.y = targetY;
    menu.draw(canvas);
  }

  void show(int x, int y) {
    targetX = x;
    targetY = y;
    visible = true;
  }

  void hide() {
    visible = false;
  }
}
