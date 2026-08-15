import 'package:window_toolkit/window_toolkit.dart';
import 'package:test/test.dart';

/// Test harness for widget tests.
///
/// Wraps a widget, manages pump cycles, and provides [expect] with
/// paint command verification.
class WidgetHarness<T extends Widget> {
  final T root;
  final RecordingPainter painter = RecordingPainter();
  int windowWidth = 200;
  int windowHeight = 200;

  WidgetHarness(this.root);

  /// Set the surface size and return self for chaining.
  WidgetHarness<T> withBounds({int width = 200, int height = 200}) {
    windowWidth = width;
    windowHeight = height;
    return this;
  }

  /// Pump one frame: measure the widget then draw it.
  void pump({int width = 200, int height = 200}) {
    final w = width ?? windowWidth;
    final h = height ?? windowHeight;
    painter.clearCommands();
    root.performLayout(w);
    root.x = 0;
    root.y = 0;
    root.draw(painter);
  }

  /// Draw and return paint commands (for chaining with expect).
  List<PaintCommand> draw() {
    pump(width: windowWidth, height: windowHeight);
    return painter.commands;
  }

  /// Assert that exactly one paint command of type [C] was recorded
  /// and return it.
  C singleCommand<C extends PaintCommand>() {
    final matching = painter.commands.whereType<C>().toList();
    expect(
      matching.length,
      1,
      reason: 'Expected exactly one ${C.runtimeType}, got ${matching.length}',
    );
    return matching.first;
  }

  /// Assert that at least one paint command of type [C] exists.
  bool hasCommand<C extends PaintCommand>() =>
      painter.commands.any((c) => c is C);
}
