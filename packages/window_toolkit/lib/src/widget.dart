import 'package:layout_engine/layout_engine.dart' as le;

import 'layer_window.dart';
import 'backend/layer.dart';
import 'mixins/event.dart';
import 'painter/painter.dart';
import 'palette.dart';
import 'style.dart';

// Re-export so widget implementations can type-check KeyEvent.
export 'mixins/event.dart' show KeyEvent;

// Re-export layout_engine Element types.
export 'package:layout_engine/layout_engine.dart'
    show
        BuildContext,
        BuildOwner,
        Element,
        ElementTree,
        WidgetKey,
        ElementWidget,
        InheritedElement,
        InheritedWidget,
        NeedsBuildCallback,
        State,
        StatefulElement,
        StatefulWidget,
        StatelessElement,
        StatelessWidget,
        WidgetElement;

typedef VoidCallback = void Function();

abstract class Widget extends le.ElementWidget {
  /// Set by [WidgetWindow] so animated widgets can trigger repaints.
  static VoidCallback? onNeedsRepaint;

  /// Parent pointer — set by containers when they lay out children.
  Widget? parent;

  /// Optional CSS id — mirrors `widget.set_name()` / `get_style_context()->add_class(id)` in GTK.
  /// Waybar uses e.g. `window#waybar`, `#pulseaudio`, `#workspaces`.
  String? styleId;

  /// CSS classes — mirrors `get_style_context()->add_class()`. Waybar adds
  /// `"module"` to every module, plus `"modules-left"` etc.
  final Set<String> styleClasses = {};

  /// Pseudo-classes — mirrors `add_class("hidden")`, `:hover`, etc.
  final Set<String> pseudoClasses = {};

  bool hasClass(String name) => styleClasses.contains(name);
  bool hasPseudoClass(String name) => pseudoClasses.contains(name) || styleClasses.contains(name);
  void addClass(String name) => styleClasses.add(name);
  void removeClass(String name) { styleClasses.remove(name); pseudoClasses.remove(name); }
  void addPseudoClass(String name) => pseudoClasses.add(name);
  void removePseudoClass(String name) => pseudoClasses.remove(name);

  /// Creates a widget with an optional [key] for reconciliation.
  Widget({super.key, this.styleId});

  /// Whether this widget is mounted in a widget tree.
  bool mounted = false;

  /// Called once when the widget is first mounted into a widget tree.
  void initState() {}

  /// Called when the widget is removed from the widget tree.
  void dispose() {}

  /// Notify the framework that internal data changed.
  /// Triggers a repaint on the next frame.
  void setState(void Function() fn) {
    fn();
    onNeedsRepaint?.call();
  }

  int x = 0, y = 0, width = 0, height = 0;
  /// Click handler. Return true to consume the event and stop propagation.
  /// The click bubbles up the widget tree: deepest widget is called first,
  /// then its parent, grandparent, etc., until a handler returns true.
  bool Function()? onClick;
  VoidCallback? onMouseEnter;
  VoidCallback? onMouseLeave;

  /// Convenience accessor for the active palette colors.
  ColorGroup get palette => Palette.current.forState(true, true);

  /// Convenience accessor for the active style.
  Style get style => Style.current;

  /// Positioned mouse callbacks. Override in interactive widgets.
  /// Called by WidgetWindow when events reach this widget via hit-test.
  void onMouseDown(int x, int y, int button) {}
  void onMouseUp(int x, int y, int button) {}
  void onMouseDrag(int x, int y) {}

  /// Keyboard input. Override in widgets that need text input.
  /// Called by WidgetWindow when this widget has keyboard focus.
  void onKeyPressed(KeyEvent event) {}
  void onKeyReleased(KeyEvent event) {}

  /// The child widgets of this widget, for hit-test traversal and layout.
  /// Override in composite widgets that contain children.
  List<Widget> get children => const [];

  /// Called when this widget gains or loses keyboard focus.
  void onFocusChanged(bool focused) {}

  /// Whether this widget accepts keyboard focus (e.g. Button, TextField).
  bool get acceptsFocus => false;

  /// Focus order for Tab key navigation. Widgets with the same
  /// [tabIndex] are focused in hit-test order. Default 0 (no focus).
  int tabIndex = 0;

  /// Whether this widget can be reached via Tab key.
  bool get isFocusable => tabIndex > 0 && acceptsFocus;

  /// Scroll / wheel input. Override in widgets that respond to scroll.
  /// Called by WidgetWindow when this widget is under the cursor.
  /// Return true to consume the event and stop propagation.
  bool onMouseWheel(MouseWheelEvent event) => false;

  void measure(Painter painter) {}

  void draw(Painter canvas);

  /// Lays out this widget within [containerWidth], setting [height] to
  /// the widget's intrinsic height after measuring its children.
  void performLayout(int containerWidth) {
    width = containerWidth;
  }

  bool hitTest(int px, int py) {
    assert(width >= 0 && height >= 0,
        'Widget $runtimeType hit-tested before layout (width=$width height=$height). '
        'Call performLayout() or pump() before hit-testing.');
    return px >= x && px < x + width && py >= y && py < y + height;
  }

  String _widgetLabel() => '$runtimeType ($x,$y) $width×$height';

  String formatTree() {
    final buf = StringBuffer();
    buf.writeln(_widgetLabel());
    for (var i = 0; i < children.length; i++) {
      final child = children[i];
      final isLast = i == children.length - 1;
      _writeTree(child, buf, '', isLast);
    }
    return buf.toString();
  }

  void _writeTree(Widget node, StringBuffer buf, String indent, bool isLast) {
    final conn = isLast ? '└── ' : '├── ';
    buf.writeln('$indent$conn${node._widgetLabel()}');
    final childIndent = indent + (isLast ? '    ' : '│   ');
    for (var i = 0; i < node.children.length; i++) {
      _writeTree(node.children[i], buf, childIndent, i == node.children.length - 1);
    }
  }

  void dumpTree({void Function(String line)? writeln}) {
    final text = formatTree();
    final out = writeln ?? (String s) => print(s);
    for (final line in text.split('\n')) {
      if (line.isNotEmpty) out(line);
    }
  }
}

class Container extends Widget {
  int spacing;

  final List<Widget> left = [];
  final List<Widget> center = [];
  final List<Widget> right = [];

  Container({this.spacing = 0});

  @override
  void draw(Painter canvas) {
    for (var w in left) {
      w.measure(canvas);
    }
    for (var w in center) {
      w.measure(canvas);
    }
    for (var w in right) {
      w.measure(canvas);
    }

    layout(width, height);
    for (var w in left) {
      w.draw(canvas);
    }
    for (var w in center) {
      w.draw(canvas);
    }
    for (var w in right) {
      w.draw(canvas);
    }
  }

  @override
  bool hitTest(int px, int py) {
    layout(width, height);
    return super.hitTest(px, py);
  }

  void layout(int containerWidth, int containerHeight) {
    height = containerHeight;

    int fixedLeft = 0, fixedCenter = 0, fixedRight = 0;
    int spacerLeft = 0, spacerCenter = 0, spacerRight = 0;

    for (var w in left) {
      if (w is Spacer) {
        spacerLeft++;
      } else {
        fixedLeft += w.width;
      }
    }
    for (var w in center) {
      if (w is Spacer) {
        spacerCenter++;
      } else {
        fixedCenter += w.width;
      }
    }
    for (var w in right) {
      if (w is Spacer) {
        spacerRight++;
      } else {
        fixedRight += w.width;
      }
    }

    fixedLeft += (left.length - 1) * spacing;
    fixedCenter += (center.length - 1) * spacing;
    fixedRight += (right.length - 1) * spacing;

    int totalSpacers = spacerLeft + spacerCenter + spacerRight;
    int remaining = containerWidth - (fixedLeft + fixedCenter + fixedRight);
    int spacerUnit = totalSpacers > 0
        ? (remaining ~/ totalSpacers).clamp(0, remaining)
        : 0;

    for (var w in left.whereType<Spacer>()) {
      w.width = spacerUnit;
    }
    for (var w in center.whereType<Spacer>()) {
      w.width = spacerUnit;
    }
    for (var w in right.whereType<Spacer>()) {
      w.width = spacerUnit;
    }

    int sectionCenter = _sectionWidth(center);
    int sectionRight = _sectionWidth(right);

    int cx = x;
    for (var child in left) {
      child.x = cx;
      child.y = y;
      child.height = containerHeight;
      cx += child.width + spacing;
    }

    cx = x + (containerWidth - sectionCenter) ~/ 2;
    for (var child in center) {
      child.x = cx;
      child.y = y;
      child.height = containerHeight;
      cx += child.width + spacing;
    }

    cx = x + containerWidth - sectionRight;
    for (var child in right) {
      child.x = cx;
      child.y = y;
      child.height = containerHeight;
      cx += child.width + spacing;
    }
  }

  int _sectionWidth(List<Widget> widgets) {
    if (widgets.isEmpty) return 0;
    int total = 0;
    for (var w in widgets) {
      total += w.width;
    }
    return total + (widgets.length - 1) * spacing;
  }
}

// Label lives in widgets/label.dart (measured text + ellipsis).

class Spacer extends Widget {
  @override
  void draw(Painter canvas) {
    // Spacer draws nothing
  }

  @override
  bool hitTest(int px, int py) => false;
}

class BarLayout {
  final List<Widget> left = [];
  final List<Widget> center = [];
  final List<Widget> right = [];

  void layout(int barWidth, int barHeight) {
    int fixedLeft = 0, fixedCenter = 0, fixedRight = 0;
    int spacerLeft = 0, spacerCenter = 0, spacerRight = 0;

    for (var w in left) {
      if (w is Spacer) {
        spacerLeft++;
      } else {
        fixedLeft += w.width;
      }
    }
    for (var w in center) {
      if (w is Spacer) {
        spacerCenter++;
      } else {
        fixedCenter += w.width;
      }
    }
    for (var w in right) {
      if (w is Spacer) {
        spacerRight++;
      } else {
        fixedRight += w.width;
      }
    }

    int totalSpacers = spacerLeft + spacerCenter + spacerRight;
    int remaining = barWidth - (fixedLeft + fixedCenter + fixedRight);
    int spacerUnit = totalSpacers > 0
        ? (remaining ~/ totalSpacers).clamp(0, remaining)
        : 0;

    for (var w in left.whereType<Spacer>()) {
      w.width = spacerUnit;
    }
    for (var w in center.whereType<Spacer>()) {
      w.width = spacerUnit;
    }
    for (var w in right.whereType<Spacer>()) {
      w.width = spacerUnit;
    }

    int sectionCenter = _sectionWidth(center);
    int sectionRight = _sectionWidth(right);

    int cx = 0;
    for (var child in left) {
      child.x = cx;
      child.y = 0;
      child.height = barHeight;
      cx += child.width;
    }

    cx = (barWidth - sectionCenter) ~/ 2;
    for (var child in center) {
      child.x = cx;
      child.y = 0;
      child.height = barHeight;
      cx += child.width;
    }

    cx = barWidth - sectionRight;
    for (var child in right) {
      child.x = cx;
      child.y = 0;
      child.height = barHeight;
      cx += child.width;
    }
  }

  void draw(Painter canvas) {
    for (var w in left) {
      w.draw(canvas);
    }
    for (var w in center) {
      w.draw(canvas);
    }
    for (var w in right) {
      w.draw(canvas);
    }
  }

  Widget? hitTest(int px, int py) {
    for (var section in [left, center, right]) {
      for (var child in section) {
        if (child.hitTest(px, py)) return child;
      }
    }
    return null;
  }

  static int _sectionWidth(List<Widget> widgets) {
    if (widgets.isEmpty) return 0;
    int total = 0;
    for (var w in widgets) {
      total += w.width;
    }
    return total;
  }
}

class BarApp extends LayerWindow {
  final BarLayout layout = BarLayout();

  BarApp({
    super.anchor = Anchor.top,
    super.barHeight = 30,
    super.exclusiveZone = 30,
    super.namespace = 'wayland-toolkit',
  });

  void addLeft(Widget widget) => layout.left.add(widget);

  void addCenter(Widget widget) => layout.center.add(widget);

  void addRight(Widget widget) => layout.right.add(widget);

  @override
  void draw(Painter canvas) {
    layout.layout(width, height);
    layout.draw(canvas);
  }

  @override
  void onMouseButtonPressed(MouseButtonEvent event) {
    final widget = layout.hitTest(event.x.toInt(), event.y.toInt());
    widget?.onClick?.call();
  }
}
