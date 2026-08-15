import '../drawing/color.dart';
import '../font/font.dart';
import '../interaction.dart';
import '../mixins/hoverable.dart';
import '../mixins/hover_animated.dart';
import '../painter/painter.dart';
import '../style.dart';
import '../style/style_patch.dart';
import '../widget.dart';

class TabBar extends Widget with Hoverable, HoverAnimated {
  @override
  List<String> labels;
  int activeIndex;
  Color activeColor;
  Color inactiveColor;
  Color indicatorColor;
  Color backgroundColor;
  Color textColor;
  int tabHeight;
  VoidCallback? onChanged;
  int _hoverIndex = -1;

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
  }) : assert(tabHeight > 0, 'TabBar tabHeight must be > 0') {
    height = tabHeight;
    onClick = () {
      if (_hoverIndex >= 0) {
        select(_hoverIndex);
        return true;
      }
      return false;
    };
  }

  @override
  bool get acceptsFocus => true;

  @override
  Style styleRole() => Style(
    color: textColor,
    backgroundColor: backgroundColor,
    borderColor: indicatorColor,
    borderWidth: 0,
  );

  @override
  void onMouseMove(int x, int y) {
    final next = tabAt(x, y);
    if (next == _hoverIndex) return;
    setState(() {
      _hoverIndex = next;
      setInteractionState(WidgetState.hovered, next >= 0);
    });
  }

  int get tabWidth => labels.isEmpty ? 0 : (width ~/ labels.length);

  @override
  void draw(Painter canvas) {
    if (labels.isEmpty) return;
    final style = resolvedStyle();

    final tw = tabWidth;

    for (var i = 0; i < labels.length; i++) {
      final tx = x + i * tw;
      final isActive = i == activeIndex;
      final isHovered = i == _hoverIndex;
      final tabStyle = isActive
          ? resolvedStyleOn(const [
              'selected',
            ], local: StylePatch(backgroundColor: activeColor))
          : resolvedStyleOn(
              isHovered ? const ['hover'] : const <String>[],
              local: StylePatch(
                backgroundColor: isHovered
                    ? Color.blend(
                        style.backgroundColor!,
                        const Color(255, 255, 255, 18),
                      )
                    : inactiveColor,
              ),
            );
      drawStyledRect(
        canvas,
        Rect.fromLTWH(
          tx.toDouble(),
          y.toDouble(),
          tw.toDouble(),
          tabHeight.toDouble(),
        ),
        style: tabStyle,
      );

      drawStyledText(
        canvas,
        labels[i],
        Offset(
          (tx + (tw - labels[i].length * 8) ~/ 2).toDouble(),
          (y + (tabHeight - 16) ~/ 2).toDouble(),
        ),
        style: style,
        color: style.color,
        fallback: const Font(pixelSize: 16),
      );
    }

    drawStyledRect(
      canvas,
      Rect.fromLTWH(
        (x + activeIndex * tw).toDouble(),
        (y + tabHeight - 2).toDouble(),
        tw.toDouble(),
        2,
      ),
      style: style.overlay(StylePatch(backgroundColor: style.borderColor)),
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

  void select(int index) {
    if (index < 0 || index >= labels.length || index == activeIndex) return;
    setState(() {
      activeIndex = index;
      setInteractionState(WidgetState.selected, true);
    });
    onChanged?.call();
  }
}

class TabView extends Widget {
  @override
  List<Widget> get children => [header, ...pages];
  final TabBar header;
  final List<Widget> pages;
  final int index; // synced from header.activeIndex

  TabView({required this.header, required this.pages, int? index})
    : index = index ?? header.activeIndex;

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
    if (header.hitTest(px, py)) return true;
    final active = header.activeIndex;
    if (active >= 0 && active < pages.length) {
      return pages[active].hitTest(px, py);
    }
    return false;
  }
}
