import '../drawing/color.dart';
import '../painter/painter.dart';
import '../widget.dart';

class TabBar extends Widget {
  List<String> labels;
  int activeIndex;
  Color activeColor;
  Color inactiveColor;
  Color indicatorColor;
  Color backgroundColor;
  Color textColor;
  int tabHeight;
  VoidCallback? onChanged;

  TabBar({
    this.labels = const [],
    this.activeIndex = 0,
    this.activeColor = const Color(50, 50, 50),
    this.inactiveColor = const Color(30, 30, 30),
    this.indicatorColor = const Color(200, 200, 200),
    this.backgroundColor = const Color(22, 22, 22),
    this.textColor = const Color(200, 200, 200),
    this.tabHeight = 28,
    this.onChanged,
  }) {
    height = tabHeight;
  }

  int get tabWidth => labels.isEmpty ? 0 : (width ~/ labels.length);

  @override
  void draw(Painter canvas) {
    if (labels.isEmpty) return;

    final tw = tabWidth;

    for (var i = 0; i < labels.length; i++) {
      final tx = x + i * tw;
      final isActive = i == activeIndex;
      canvas.drawRect(
        Rect.fromLTWH(tx.toDouble(), y.toDouble(), tw.toDouble(), tabHeight.toDouble()),
        Paint()..color = isActive ? activeColor : inactiveColor,
      );

      canvas.drawText(
        labels[i],
        Offset(
          (tx + (tw - labels[i].length * 8) ~/ 2).toDouble(),
          (y + (tabHeight - 16) ~/ 2).toDouble(),
        ),
        color: textColor,
        size: 16,
      );
    }

    canvas.drawRect(
      Rect.fromLTWH(
        (x + activeIndex * tw).toDouble(),
        (y + tabHeight - 2).toDouble(),
        tw.toDouble(),
        2,
      ),
      Paint()..color = indicatorColor,
    );
  }

  int tabAt(int px, int py) {
    if (labels.isEmpty || width <= 0) return -1;
    final tw = tabWidth;
    final index = (px - x) ~/ tw;
    if (index >= 0 && index < labels.length) {
      if (px >= x && px < x + width && py >= y && py < y + height) {
        return index;
      }
    }
    return -1;
  }
}

class TabView extends Widget {
  final TabBar header;
  final List<Widget> pages;
  final int index; // synced from header.activeIndex

  TabView({
    required this.header,
    required this.pages,
    int? index,
  }) : index = index ?? header.activeIndex;

  @override
  void draw(Painter canvas) {
    header.x = x;
    header.y = y;
    header.width = width;
    header.draw(canvas);

    final contentY = y + header.height;
    final contentH = height - header.height;
    if (contentH <= 0) return;

    final active = header.activeIndex;
    if (active >= 0 && active < pages.length) {
      final page = pages[active];
      page.x = x;
      page.y = contentY;
      page.width = width;
      page.height = contentH;
      page.draw(canvas);
    }
  }

  @override
  bool hitTest(int px, int py) {
    if (!super.hitTest(px, py)) return false;
    final active = header.activeIndex;
    if (active >= 0 && active < pages.length) {
      return pages[active].hitTest(px, py);
    }
    return false;
  }
}
