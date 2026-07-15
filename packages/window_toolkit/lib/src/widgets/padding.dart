import 'package:layout_engine/layout_engine.dart' as le;

import '../painter/painter.dart';
import '../widget.dart';

/// Insets child by given amounts, backed by [le.RenderPadding].
class Padding extends Widget {
  @override
  List<Widget> get children => [child];

  Widget child;
  int left;
  int top;
  int right;
  int bottom;
  final le.RenderPadding _renderPadding = le.RenderPadding();
  final _RenderWidgetBox _renderChild = _RenderWidgetBox(null);

  Padding({
    required this.child,
    this.left = 0,
    this.top = 0,
    this.right = 0,
    this.bottom = 0,
    int? all,
  })  : assert(left >= 0 && top >= 0 && right >= 0 && bottom >= 0,
            'Padding values must be >= 0') {
    if (all != null) {
      left = all;
      top = all;
      right = all;
      bottom = all;
    }
  }

  @override
  void performLayout(int containerWidth) {
    _renderPadding.left = left.toDouble();
    _renderPadding.top = top.toDouble();
    _renderPadding.right = right.toDouble();
    _renderPadding.bottom = bottom.toDouble();

    _renderChild.widget = child;
    if (_renderPadding.children.isEmpty) {
      _renderPadding.attach(_renderChild);
    }

    child.performLayout((containerWidth - left - right).clamp(0, containerWidth));
    _renderChild.size = le.Size(child.width.toDouble(), child.height.toDouble());

    _renderPadding.layout(le.BoxConstraints(
      maxWidth: containerWidth.toDouble(),
      maxHeight: double.infinity,
    ));

    width = _renderPadding.size.width.round();
    height = _renderPadding.size.height.round();
    child.x = x + left;
    child.y = y + top;
    child.width = (width - left - right).clamp(0, width);
  }

  @override
  void draw(Painter canvas) {
    if (_renderChild.size.width <= 0 && width > 0) {
      performLayout(width);
    }
    child.draw(canvas);
  }

  @override
  bool hitTest(int px, int py) {
    if (!super.hitTest(px, py)) return false;
    return child.hitTest(px, py);
  }
}

class _RenderWidgetBox extends le.RenderBox {
  Widget? widget;
  _RenderWidgetBox(this.widget);

  @override
  void layout(le.BoxConstraints constraints) {
    if (widget == null) return;
    widget!.performLayout(constraints.maxWidth.round());
    size = le.Size(widget!.width.toDouble(), widget!.height.toDouble());
  }
}
