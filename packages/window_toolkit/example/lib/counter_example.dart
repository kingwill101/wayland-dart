/// Stateful counter demo using StatefulWidget + ElementHost.
///
/// CounterWidget extends StatefulWidget (from layout_engine) for Element
/// tree lifecycle. Wrap it in ElementHost to use inside rendering containers.
import 'package:layout_engine/layout_engine.dart'
    show BuildContext, ElementWidget, State, StatefulWidget, StatelessWidget;
import 'package:window_toolkit/window_toolkit.dart';

/// Stateful counter with increment/decrement/reset.
class CounterWidget extends StatefulWidget {
  final String label;
  CounterWidget({this.label = 'Counter'});

  @override
  State createState() => _CounterState();
}

class _CounterState extends State<CounterWidget> {
  int _count = 0;

  @override
  ElementWidget build(BuildContext context) {
    return _CounterRender(
      label: widget.label,
      count: _count,
      onIncrement: () => setState(() => _count++),
      onDecrement: () => setState(() => _count--),
      onReset: () => setState(() => _count = 0),
    );
  }
}

/// The actual rendering widget — a plain Widget with draw/performLayout/hitTest.
class _CounterRender extends Widget {
  final String label;
  final int count;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onReset;

  _CounterRender({
    required this.label,
    required this.count,
    required this.onIncrement,
    required this.onDecrement,
    required this.onReset,
  });

  late final Button _decBtn = Button('−', onPressed: onDecrement);
  late final Button _incBtn = Button('+', onPressed: onIncrement);
  late final Button _resetBtn = Button('Reset', onPressed: onReset);

  @override
  void draw(Painter canvas) {
    canvas.drawRRect(
      Rect.fromLTWH(x.toDouble(), y.toDouble(), width.toDouble(), height.toDouble()),
      4, 4,
      Paint()..color = palette.mid,
    );

    final labelW = Label('$label: $count');
    labelW.x = x + 4;
    labelW.y = y + 2;
    labelW.draw(canvas);

    var bx = x + width - 4;
    _resetBtn
      ..x = bx - _resetBtn.width
      ..y = y + 2
      ..draw(canvas);
    bx -= _resetBtn.width + 4;
    _incBtn
      ..x = bx - _incBtn.width
      ..y = y + 2
      ..draw(canvas);
    bx -= _incBtn.width + 4;
    _decBtn
      ..x = bx - _decBtn.width
      ..y = y + 2
      ..draw(canvas);
  }

  @override
  void performLayout(int containerWidth) {
    width = containerWidth;
    height = 28;
    _decBtn.performLayout(width);
    _incBtn.performLayout(width);
    _resetBtn.performLayout(width);
  }

  @override
  bool hitTest(int px, int py) {
    if (!super.hitTest(px, py)) return false;
    if (_decBtn.hitTest(px, py) ||
        _incBtn.hitTest(px, py) ||
        _resetBtn.hitTest(px, py)) {
      return true;
    }
    // Click on background doesn't interact
    return false;
  }
}

/// Example usage inside a VBox:
/// ```dart
/// VBox(children: [
///   ElementHost(child: CounterWidget(label: 'Demo')),
/// ])
/// ```
