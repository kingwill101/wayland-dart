/// Inset layout: [RenderPadding] insets its child by a fixed amount.
library;

import 'geometry.dart';
import 'render_object.dart';

/// Render object that insets its single child by [left], [top], [right], [bottom].
class RenderPadding extends RenderBox {
  double left;
  double top;
  double right;
  double bottom;

  EdgeInsets get padding => EdgeInsets.fromLTRB(left, top, right, bottom);
  set padding(EdgeInsets insets) {
    left = insets.left;
    top = insets.top;
    right = insets.right;
    bottom = insets.bottom;
  }

  RenderBox? get paddedChild => children.isNotEmpty ? children.first as RenderBox? : null;

  RenderPadding({
    this.left = 0,
    this.top = 0,
    this.right = 0,
    this.bottom = 0,
    EdgeInsets? padding,
  })  : assert(padding == null || left == 0 && top == 0 && right == 0 && bottom == 0,
            'Provide either padding or left/top/right/bottom, not both'),
        assert(left >= 0 && top >= 0 && right >= 0 && bottom >= 0,
            'RenderPadding values must be >= 0') {
    if (padding != null) {
      left = padding.left;
      top = padding.top;
      right = padding.right;
      bottom = padding.bottom;
    }
  }

  RenderPadding.withPadding(EdgeInsets insets)
      : left = insets.left,
        top = insets.top,
        right = insets.right,
        bottom = insets.bottom;

  @override
  void layout(BoxConstraints constraints) {
    if (children.isEmpty) {
      size = constraints.constrain(Size.zero);
      return;
    }

    final child = children.first;
    final innerConstraints = BoxConstraints(
      minWidth: (constraints.minWidth - left - right).clamp(0, double.infinity),
      maxWidth: (constraints.maxWidth - left - right).clamp(0, double.infinity),
      minHeight: (constraints.minHeight - top - bottom).clamp(0, double.infinity),
      maxHeight: (constraints.maxHeight - top - bottom).clamp(0, double.infinity),
    );
    child.layout(innerConstraints);
    child.offset = Offset(left, top);

    size = constraints.constrain(Size(
      child.size.width + left + right,
      child.size.height + top + bottom,
    ));
  }
}
