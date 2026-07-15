import '../drawing/color.dart';
import '../event_loop.dart';
import '../mixins/event.dart';
import '../painter/painter.dart';
import '../widget.dart';

class ScrollArea extends Widget {
  @override
  @override
  List<Widget> get children => [child];

  final Widget child;
  int scrollX;
  int scrollY;
  int scrollbarWidth;
  Color? _scrollbarColor;
  Color? _scrollbarBg;
  Color? _scrollbarHoverColor;
  bool showHorizontal;
  bool showVertical;
  int? _dragAxis;
  int _dragStartScroll = 0;
  int _dragStartCoord = 0;

  double _velocityY = 0;
  Timer? _smoothTimer;
  VoidCallback? onSmoothScroll;

  ScrollArea({
    required this.child,
    this.scrollX = 0,
    this.scrollY = 0,
    this.scrollbarWidth = 6,
    Color? scrollbarColor,
    Color? scrollbarBg,
    Color? scrollbarHoverColor,
    this.showHorizontal = false,
    this.showVertical = true,
  })  : _scrollbarColor = scrollbarColor,
        _scrollbarBg = scrollbarBg,
        _scrollbarHoverColor = scrollbarHoverColor;

  Color get scrollbarColor => _scrollbarColor ?? palette.light;
  Color get scrollbarBg => _scrollbarBg ?? palette.mid;
  Color get scrollbarHoverColor => _scrollbarHoverColor ?? palette.windowText;

  int get _contentWidth => child.width > 0 ? child.width : width;
  int get _contentHeight {
    child.performLayout(width);
    return child.height > 0 ? child.height : height;
  }

  int get maxScrollX => (_contentWidth - width).clamp(0, _contentWidth);
  int get maxScrollY => (_contentHeight - height).clamp(0, _contentHeight);

  void scrollBy(int dx, int dy) {
    scrollX = (scrollX + dx).clamp(0, maxScrollX);
    scrollY = (scrollY + dy).clamp(0, maxScrollY);
  }

  bool isOnScrollbar(int px, int py) {
    if (showVertical && maxScrollY > 0) {
      final sbx = x + width - scrollbarWidth;
      if (px >= sbx && px < sbx + scrollbarWidth && py >= y && py < y + height) return true;
    }
    if (showHorizontal && maxScrollX > 0) {
      final sby = y + height - scrollbarWidth;
      if (py >= sby && py < sby + scrollbarWidth && px >= x && px < x + width) return true;
    }
    return false;
  }

  @override
  bool onMouseWheel(MouseWheelEvent event) {
    final dx = event.dx.round();
    final dy = event.dy.round();
    if (dy != 0) {
      final step = dy > 0 ? 40 : -40;
      scrollBy(0, step);
      _velocityY += dy * 1.2;
      _startSmoothScroll();
    }
    if (dx != 0) {
      scrollBy(dx > 0 ? 40 : dx < 0 ? -40 : 0, 0);
    }
    return true;
  }

  void _startSmoothScroll() {
    _smoothTimer?.cancel();
    _smoothTimer = EventLoop.instance.addTimer(
      const Duration(milliseconds: 16),
      _tickSmooth,
    );
  }

  void _tickSmooth() {
    if (_velocityY.abs() < 1) {
      _velocityY = 0;
      _smoothTimer?.cancel();
      _smoothTimer = null;
      return;
    }
    scrollBy(0, _velocityY.round());
    _velocityY *= 0.85;
    onSmoothScroll?.call();
  }

  @override
  void onMouseDown(int x, int y, int button) {
    if (button != 272) return;
    if (showVertical && maxScrollY > 0) {
      final tX = this.x + width - scrollbarWidth;
      if (x >= tX && x < tX + scrollbarWidth && y >= this.y && y < this.y + height) {
        final thumbH = (height * height ~/ _contentHeight).clamp(10, height);
        final thumbY = this.y + (scrollY * (height - thumbH) ~/ maxScrollY).clamp(0, height - thumbH);
        if (y >= thumbY && y < thumbY + thumbH) {
          _dragAxis = 1;
          _dragStartScroll = scrollY;
          _dragStartCoord = y;
        } else {
          scrollBy(0, y < thumbY ? -height : height);
        }
        return;
      }
    }
    if (showHorizontal && maxScrollX > 0) {
      final tY = this.y + height - scrollbarWidth;
      if (y >= tY && y < tY + scrollbarWidth && x >= this.x && x < this.x + width) {
        final thumbW = (width * width ~/ _contentWidth).clamp(10, width);
        final thumbX = this.x + (scrollX * (width - thumbW) ~/ maxScrollX).clamp(0, width - thumbW);
        if (x >= thumbX && x < thumbX + thumbW) {
          _dragAxis = 2;
          _dragStartScroll = scrollX;
          _dragStartCoord = x;
        } else {
          scrollBy(x < thumbX ? -width : width, 0);
        }
      }
    }
  }

  @override
  void onMouseDrag(int x, int y) {
    if (_dragAxis == 1) {
      final thumbH = (height * height ~/ _contentHeight).clamp(10, height);
      final dragRange = height - thumbH;
      if (dragRange > 0) {
        final delta = y - _dragStartCoord;
        scrollY = (_dragStartScroll + delta * maxScrollY ~/ dragRange).clamp(0, maxScrollY);
      }
    } else if (_dragAxis == 2) {
      final thumbW = (width * width ~/ _contentWidth).clamp(10, width);
      final dragRange = width - thumbW;
      if (dragRange > 0) {
        final delta = x - _dragStartCoord;
        scrollX = (_dragStartScroll + delta * maxScrollX ~/ dragRange).clamp(0, maxScrollX);
      }
    }
  }

  @override
  void onMouseUp(int x, int y, int button) {
    _dragAxis = null;
  }

  @override
  void performLayout(int containerWidth) {
    width = containerWidth;
    child.performLayout(width);
    child.x = x;
    child.y = y;
  }

  @override
  void draw(Painter canvas) {
    canvas.save();
    canvas.clipRect(
      Rect.fromLTWH(x.toDouble(), y.toDouble(), width.toDouble(), height.toDouble()),
    );
    canvas.translate(-scrollX.toDouble(), -scrollY.toDouble());
    child
      ..x = x
      ..y = y;
    child.draw(canvas);
    canvas.restore();

    if (showVertical && maxScrollY > 0 && height > 0) {
      final tX = (x + width - scrollbarWidth).toDouble();
      canvas.drawRect(
        Rect.fromLTWH(tX, y.toDouble(), scrollbarWidth.toDouble(), height.toDouble()),
        Paint()..color = scrollbarBg,
      );
      final thumbH = (height * height ~/ _contentHeight).clamp(10, height);
      final thumbY = (scrollY * (height - thumbH) ~/ maxScrollY).clamp(0, height - thumbH);
      canvas.drawRect(
        Rect.fromLTWH(tX, (y + thumbY).toDouble(), scrollbarWidth.toDouble(), thumbH.toDouble()),
        Paint()..color = _dragAxis == 1 ? scrollbarHoverColor : scrollbarColor,
      );
    }

    if (showHorizontal && maxScrollX > 0 && width > 0) {
      final tY = (y + height - scrollbarWidth).toDouble();
      canvas.drawRect(
        Rect.fromLTWH(x.toDouble(), tY, width.toDouble(), scrollbarWidth.toDouble()),
        Paint()..color = scrollbarBg,
      );
      final thumbW = (width * width ~/ _contentWidth).clamp(10, width);
      final thumbX = (scrollX * (width - thumbW) ~/ maxScrollX).clamp(0, width - thumbW);
      canvas.drawRect(
        Rect.fromLTWH((x + thumbX).toDouble(), tY, thumbW.toDouble(), scrollbarWidth.toDouble()),
        Paint()..color = _dragAxis == 2 ? scrollbarHoverColor : scrollbarColor,
      );
    }
  }

  @override
  bool hitTest(int px, int py) {
    if (!super.hitTest(px, py)) return false;
    final childPx = px + scrollX;
    final childPy = py + scrollY;
    child
      ..x = x
      ..y = y;
    return child.hitTest(childPx, childPy);
  }
}
