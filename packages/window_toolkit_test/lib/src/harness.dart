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
  void pumpWidget(Widget widget) {
    _root = widget;
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
    if (w is Padding) _collectRecursive(w.child);
    if (w is Align) _collectRecursive(w.child);
    if (w is HBox) for (final c in w.children) _collectRecursive(c);
    if (w is VBox) for (final c in w.children) _collectRecursive(c);
    if (w is ScrollArea) {
      _collectRecursive(w.child);
    }
    if (w is Center) _collectRecursive(w.child);
  }
}
