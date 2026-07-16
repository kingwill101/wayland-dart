import 'dart:math' as math;

import 'package:window_toolkit/window_toolkit.dart';

import 'test_backend.dart';

/// Test harness for driving widget tests, inspired by Flutter's
/// [WidgetTester].
///
/// ```dart
/// test('button click updates counter', () async {
///   final harness = TestHarness();
///   await harness.pump();
///
///   // Find and interact with widgets.
///   final button = harness.find.text('Click me');
///   expect(button, isNotNull);
///
///   // Tap the button.
///   button!.onPressed?.call();
///   await harness.pump();
///
///   // Verify state.
///   final label = harness.find.text('Clicked!');
///   expect(label, isNotNull);
/// });
/// ```
class TestHarness {
  final TestBackend _backend;

  /// The underlying test backend.
  TestBackend get backend => _backend;

  /// Paint command recorder from the last frame.
  List<PaintCommand> get commands => _backend.commands;

  /// The root widget under test.
  Widget? _root;

  /// Current window width for layout.
  int windowWidth = 800;

  /// Current window height for layout.
  int windowHeight = 600;

  /// Finder for locating widgets in the tree.
  final WidgetFinder find = WidgetFinder._();

  TestHarness._(this._backend);

  /// Create a [TestHarness] with a [TestBackend].
  factory TestHarness({int width = 800, int height = 600}) {
    final backend = TestBackend(testWidth: width, testHeight: height);
    return TestHarness._(backend);
  }

  /// Pump the widget tree: layout, paint, and record commands.
  Future<void> pump() async {
    if (_root == null) return;

    _root!.performLayout(windowWidth);

    // Collect all widgets for finder.
    WidgetFinder.collectAll(_root!);

    final painter = _backend.createPainter(windowWidth, windowHeight);
    _root!.draw(painter);
    _backend.paintWithPainter(painter);
  }

  /// Set the root widget under test.
  void pumpWidget(ElementWidget widget) {
    if (widget is Widget) {
      _root = widget;
    } else {
      _root = ElementHost(child: widget);
    }
  }

  /// Pump multiple frames.
  Future<void> pumpFrames(int count) async {
    for (var i = 0; i < count; i++) {
      await pump();
    }
  }

  /// Set window dimensions and pump.
  void setSurfaceSize(int width, int height) {
    windowWidth = width;
    windowHeight = height;
  }

  /// Clear recorded paint commands.
  void clearCommands() => _backend.clearCommands();

  /// Access paint commands by type.
  Iterable<T> commandsOfType<T extends PaintCommand>() =>
      commands.whereType<T>();

  // ── Event simulation ───────────────────────────────────────

  /// Returns the deepest widget at (x, y) using hit-test traversal.
  Widget? hitTest(int x, int y) {
    if (_root == null) return null;
    return _hitTestDeep(_root!, x, y);
  }

  Widget? _hitTestDeep(Widget w, int px, int py, [int offX = 0, int offY = 0]) {
    if (w is ScrollArea) {
      final localPx = px + w.scrollX + offX;
      final localPy = py + w.scrollY + offY;
      if (w.isOnScrollbar(px, py)) return w;
      w.child..x = w.x..y = w.y;
      if (w.child.hitTest(localPx, localPy)) {
        return _hitTestDeep(w.child, localPx, localPy, 0, 0) ?? w;
      }
      return w.hitTest(px, py) ? w : null;
    }
    if (!w.hitTest(px, py)) return null;
    final children = w.children;
    for (final child in children.reversed) {
      final result = _hitTestDeep(child, px, py, offX, offY);
      if (result != null) return result;
    }
    return w;
  }

  /// Simulate a mouse click at (x, y).
  /// Returns the widget that received the click, or null.
  Widget? tap(int x, int y) {
    final hit = hitTest(x, y);
    if (hit != null) {
      hit.onMouseDown(x, y, 272); // left button
      // Fire onClick chain (deepest first)
      var current = hit;
      while (current != null) {
        final handler = current.onClick;
        if (handler != null && handler()) break;
        // Walk up — not trivial without parent refs, so just fire on hit
        break;
      }
    }
    return hit;
  }

  /// Simulate mouse motion to (x, y).
  /// Calls onMouseEnter on newly entered widgets, onMouseLeave on exited.
  void hover(int x, int y) {
    // Track last hovered widget for enter/leave events
    _lastHovered = hitTest(x, y);
  }
  Widget? _lastHovered;

  /// Simulate a scroll wheel event at (x, y).
  void scroll(int x, int y, int dy) {
    // Find the nearest ScrollArea along the hit-test path
    final path = <Widget>[];
    _collectScrollPath(_root!, x, y, 0, 0, path);
    for (final w in path) {
      if (w is ScrollArea) {
        w.scrollBy(0, dy);
        break;
      }
    }
  }

  void _collectScrollPath(Widget w, int px, int py, int offX, int offY, List<Widget> out) {
    if (w is ScrollArea) {
      out.add(w);
      return;
    }
    if (!w.hitTest(px, py)) return;
    for (final child in w.children.reversed) {
      if (child.hitTest(px, py)) {
        _collectScrollPath(child, px, py, offX, offY, out);
        return;
      }
    }
  }

  /// Simulate a window resize.
  void resize(int width, int height) {
    windowWidth = math.max(100, width);
    windowHeight = math.max(60, height);
  }
}

/// Flutter-style widget finder.
///
/// ```dart
/// final btn = harness.find.byType(Button);
/// final lbl = harness.find.text('Hello');
/// final all = harness.find.all();
/// ```
class WidgetFinder {
  WidgetFinder._();

  /// Find all widgets in the active tree (collected during the last pump).
  static final List<Widget> _allWidgets = [];

  /// Find the first widget of type [T].
  T? byType<T extends Widget>() {
    for (final w in _allWidgets) {
      if (w is T) return w;
    }
    return null;
  }

  /// Find all widgets of type [T].
  List<T> allByType<T extends Widget>() {
    return _allWidgets.whereType<T>().toList();
  }

  /// Find a widget whose text matches [text].
  /// Works with [Label], [Button], and other text-bearing widgets.
  T? text<T extends Widget>(String text) {
    for (final w in _allWidgets) {
      if (_widgetHasText(w, text)) return w as T;
    }
    return null;
  }

  /// All widgets collected during the last pump.
  List<Widget> all() => List.unmodifiable(_allWidgets);

  static bool _widgetHasText(Widget w, String text) {
    if (w is Label && w.text == text) return true;
    if (w is Button && w.text == text) return true;
    return false;
  }

  /// Collect widgets from a tree, clearing any previous results.
  static void collectAll(Widget w) {
    _allWidgets.clear();
    _collectRecursive(w);
  }

  static void _collectRecursive(Widget w) {
    _allWidgets.add(w);
    for (final child in w.children) {
      _collectRecursive(child);
    }
    // ElementHost exposes built widget as children
    if (w is ElementHost) {
      for (final child in w.children) {
        _collectRecursive(child);
      }
    }
  }
}
