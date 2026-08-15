import 'package:window_toolkit/window_toolkit.dart';

/// Toolkit-neutral data used to render a D-Bus menu.
///
/// Keeping this separate from the D-Bus transport makes the menu testable and
/// lets the same widget be hosted by a layer popup, an xdg popup, or a future
/// desktop backend.
class TrayMenuItemData {
  final int id;
  final String label;
  final bool separator;
  final bool enabled;

  const TrayMenuItemData({
    required this.id,
    required this.label,
    this.separator = false,
    this.enabled = true,
  });
}

/// A CSS/styleable dbusmenu tree.
///
/// All visible text and controls are toolkit widgets. The composite owns only
/// the menu-specific row geometry; fonts, text shaping, box painting, hover
/// transitions, and activation state stay in the toolkit primitives.
class TrayMenuWidget extends Widget {
  final List<TrayMenuItemData> entries;
  final void Function(int id)? onTriggered;
  final List<Widget> _children;

  static const int rowHeight = 28;
  static const int separatorHeight = 8;
  static const int horizontalPadding = 8;
  static const int minWidth = 160;
  static const int maxWidth = 420;

  TrayMenuWidget({
    required List<TrayMenuItemData> entries,
    this.onTriggered,
  }) : entries = List.unmodifiable(entries),
       _children = [] {
    styleId = 'tray-menu';
    addClass('popup');
    addClass('menu');
    _rebuildChildren();
    width = preferredWidth;
    height = preferredHeight;
  }

  @override
  List<Widget> get children => _children;

  List<MenuItem> get menuItems => [
    for (final child in _children)
      if (child is MenuItem) child,
  ];

  int get preferredWidth {
    var chars = 8;
    for (final entry in entries) {
      if (!entry.separator && entry.label.length > chars) {
        chars = entry.label.length;
      }
    }
    return (chars * 8 + horizontalPadding * 2 + 24).clamp(
      minWidth,
      maxWidth,
    );
  }

  int get preferredHeight =>
      horizontalPadding +
      _children.fold<int>(0, (sum, child) {
        if (child is Separator) return sum + separatorHeight;
        return sum + rowHeight;
      });

  void _rebuildChildren() {
    _children
      ..clear()
      ..addAll(
        entries.map((entry) {
          if (entry.separator) {
            final separator = Separator(margin: horizontalPadding)
              ..styleId = 'tray-menu-separator';
            separator.addClass('tray-menu-separator');
            return separator;
          }
          final item = MenuItem(
            entry.label.isEmpty ? ' ' : entry.label,
            itemHeight: rowHeight,
            onTriggered: () => onTriggered?.call(entry.id),
          )
            ..styleId = 'tray-menu-item'
            ..enabled = entry.enabled;
          item.addClass('tray-menu-item');
          if (!entry.enabled) item.addClass('disabled');
          return item;
        }),
      );
  }

  @override
  Style styleRole() => Style(
    color: const Color(240, 240, 245),
    backgroundColor: const Color(32, 32, 36),
    borderColor: const Color(90, 90, 100),
    borderWidth: 1,
    borderRadius: 6,
  );

  @override
  void measure(Painter painter) {
    for (final child in _children) {
      if (child is MenuItem) child.measure(painter);
    }
    width = preferredWidth;
    height = preferredHeight;
  }

  @override
  void performLayout(int containerWidth) {
    width = preferredWidth;
    height = preferredHeight;
    var cy = y + horizontalPadding ~/ 2;
    for (final child in _children) {
      child
        ..parent = this
        ..x = x + horizontalPadding
        ..y = cy
        ..width = width - horizontalPadding * 2;
      if (child is Separator) {
        child.height = separatorHeight;
      } else {
        child.height = rowHeight;
      }
      cy += child.height;
    }
  }

  @override
  void draw(Painter canvas) {
    performLayout(width);
    drawStyledBox(canvas);
    for (final child in _children) {
      child.draw(canvas);
    }
  }

  @override
  bool hitTest(int px, int py) {
    if (!super.hitTest(px, py)) return false;
    performLayout(width);
    return _children.any((child) => child.hitTest(px, py));
  }
}
