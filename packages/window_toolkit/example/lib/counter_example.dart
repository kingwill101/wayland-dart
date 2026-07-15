/// Stateful counter demo — uses imperative setState-like pattern.
import 'package:window_toolkit/window_toolkit.dart';

/// A counter with increment/decrement/reset buttons.
/// Uses a manual rebuild pattern (Window.requestRedraw) since the Element
/// tree currently manages only the root widget.
class CounterWidget extends Widget {
  int _count = 0;
  final String label;
  final VoidCallback? onChanged;

  CounterWidget({this.label = 'Counter', this.onChanged});

  void increment() {
    _count++;
    Widget.onNeedsRepaint?.call();
    onChanged?.call();
  }

  void decrement() {
    _count--;
    Widget.onNeedsRepaint?.call();
    onChanged?.call();
  }

  void reset() {
    _count = 0;
    Widget.onNeedsRepaint?.call();
    onChanged?.call();
  }

  @override
  void draw(Painter canvas) {
    // Background
    canvas.drawRRect(
      Rect.fromLTWH(x.toDouble(), y.toDouble(), width.toDouble(), height.toDouble()),
      4, 4,
      Paint()..color = palette.mid,
    );

    // Label
    final labelWidget = Label('$label: $_count');
    labelWidget.x = x + 4;
    labelWidget.y = y + 2;
    labelWidget.draw(canvas);

    // Buttons
    final decBtn = Button('−', onPressed: decrement);
    final incBtn = Button('+', onPressed: increment);
    final resetBtn = Button('Reset', onPressed: reset);

    var bx = x + width - 4;
    resetBtn.x = bx - resetBtn.width;
    resetBtn.y = y + 2;
    bx -= resetBtn.width + 4;
    incBtn.x = bx - incBtn.width;
    incBtn.y = y + 2;
    bx -= incBtn.width + 4;
    decBtn.x = bx - decBtn.width;
    decBtn.y = y + 2;

    resetBtn.draw(canvas);
    incBtn.draw(canvas);
    decBtn.draw(canvas);
  }

  @override
  void performLayout(int containerWidth) {
    width = containerWidth;
    height = 28;
  }

  @override
  bool hitTest(int px, int py) {
    if (!super.hitTest(px, py)) return false;
    // Delegate to buttons
    return true;
  }
}
