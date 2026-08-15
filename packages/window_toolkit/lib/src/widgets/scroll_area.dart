import 'package:layout_engine/layout_engine.dart' as le;

import '../animation/animation_controller.dart';
import '../animation/curves.dart';
import '../animation/simulation.dart';
import '../drawing/color.dart';
import '../mixins/event.dart';
import '../painter/painter.dart';
import '../widget.dart';

/// Scrollable area backed by [le.RenderViewport] and [le.ViewportScrollController].
///
/// Supports smooth animated scrolling and fling physics via [FrictionSimulation]
/// for mouse wheel events.
class ScrollArea extends Widget {
  @override
  List<Widget> get children => [child];

  final Widget child;
  int scrollbarWidth;
  final Color? _scrollbarColor;
  final Color? _scrollbarBg;
  final Color? _scrollbarHoverColor;
  bool showHorizontal;
  bool showVertical;
  int? _dragAxis;
  int _dragStartScroll = 0;
  int _dragStartCoord = 0;

  /// Enable fling physics on mouse wheel events.
  bool enableFling;

  final le.ViewportScrollController _controller = le.ViewportScrollController();
  final le.RenderViewport _viewport = le.RenderViewport();
  final _ChildBox _childBox = _ChildBox(null);
  AnimationController? _animCtrl;
  SimulationController? _flingCtrl;

  ScrollArea({
    required this.child,
    this.scrollbarWidth = 6,
    Color? scrollbarColor,
    Color? scrollbarBg,
    Color? scrollbarHoverColor,
    this.showHorizontal = false,
    this.showVertical = true,
    this.enableFling = true,
    int initialScrollY = 0,
  }) : _scrollbarColor = scrollbarColor,
       _scrollbarBg = scrollbarBg,
       _scrollbarHoverColor = scrollbarHoverColor {
    _initScroll();
    _initialScrollY = initialScrollY;
  }

  int _initialScrollY = 0;

  /// Legacy callback for WidgetWindow smooth scroll repaint.
  /// The animated scroll now calls [Widget.onNeedsRepaint] automatically.
  VoidCallback? onSmoothScroll;

  Color get scrollbarColor => _scrollbarColor ?? palette.light;
  Color get scrollbarBg => _scrollbarBg ?? palette.mid;
  Color get scrollbarHoverColor => _scrollbarHoverColor ?? palette.windowText;

  int get scrollY => _controller.offset;
  int get scrollX => 0; // horizontal scroll not yet handled by controller

  int get _contentHeight => _controller.contentExtent;
  int get maxScrollY => _controller.maxOffset;

  void _initScroll() {
    _viewport.scrollDirection = le.Axis.vertical;
    _viewport.controller = _controller;
    if (_viewport.children.isEmpty) {
      _viewport.attach(_childBox);
    }
  }

  void scrollBy(int dx, int dy) {
    _controller.scrollBy(dy);
  }

  int get maxScrollX => 0;

  bool isOnScrollbar(int px, int py) {
    if (showVertical && maxScrollY > 0) {
      final sbx = x + width - scrollbarWidth;
      if (px >= sbx && px < sbx + scrollbarWidth && py >= y && py < y + height)
        return true;
    }
    if (showHorizontal && maxScrollX > 0) {
      final sby = y + height - scrollbarWidth;
      if (py >= sby && py < sby + scrollbarWidth && px >= x && px < x + width)
        return true;
    }
    return false;
  }

  @override
  bool onMouseWheel(MouseWheelEvent event) {
    final dy = event.dy.round();
    if (dy != 0) {
      if (enableFling && maxScrollY > 0) {
        _flingScroll(dy);
      } else {
        final step = dy > 0 ? 40 : -40;
        _controller.scrollBy(step);
        _animatedSmoothScroll(
          _controller.offset + (step > 0 ? step * 2 : step * 2),
        );
      }
    }
    return true;
  }

  /// Start a fling scroll from the current wheel event.
  void _flingScroll(int delta) {
    _flingCtrl?.dispose();
    _animCtrl?.dispose();

    // Apply immediate scroll for instant feedback.
    final step = delta > 0 ? 40 : -40;
    _controller.scrollBy(step);
    final currentOffset = _controller.offset.toDouble();

    // Map wheel delta to an initial velocity (pixels/second).
    final velocity = delta * 500.0; // scale for feel, sign = direction
    final sim = FrictionSimulation(
      initialPosition: currentOffset,
      initialVelocity: velocity,
      friction: 3.0, // higher = faster deceleration
    );

    _flingCtrl = SimulationController(simulation: sim);
    _flingCtrl!.addListener(_onFlingTick);
    _flingCtrl!.start();
  }

  void _onFlingTick() {
    final pos = _flingCtrl!.value.round();
    final clamped = pos.clamp(0, maxScrollY);
    _controller.jumpTo(clamped);
    requestRepaint();

    // Stop fling when we hit a boundary.
    if (clamped != pos) {
      _flingCtrl?.stop();
    }
  }

  void _animatedSmoothScroll(int target) {
    _animCtrl?.dispose();
    _flingCtrl?.dispose();
    final startY = _controller.offset;
    final distance = (target - startY).abs();
    if (distance == 0) return;
    final duration = Duration(
      milliseconds: (distance * 0.8).round().clamp(50, 300),
    );

    _animCtrl = AnimationController(duration: duration, curve: easeOut);
    _animCtrl!.addListener(() {
      final t = _animCtrl!.value;
      final pos = (startY + (target - startY) * t).round().clamp(0, maxScrollY);
      _controller.jumpTo(pos);
      requestRepaint();
    });
    _animCtrl!.forward();
  }

  @override
  void onMouseDown(int x, int y, int button) {
    if (button != 272) return;
    if (showVertical && maxScrollY > 0) {
      final tX = this.x + width - scrollbarWidth;
      if (x >= tX &&
          x < tX + scrollbarWidth &&
          y >= this.y &&
          y < this.y + height) {
        final thumbH = _thumbHeight();
        final thumbY =
            this.y +
            (_controller.offset * (height - thumbH) ~/ maxScrollY).clamp(
              0,
              height - thumbH,
            );
        if (y >= thumbY && y < thumbY + thumbH) {
          _dragAxis = 1;
          _dragStartScroll = _controller.offset;
          _dragStartCoord = y;
        } else {
          _animatedSmoothScroll(
            y < thumbY
                ? _controller.offset - height
                : _controller.offset + height,
          );
        }
        return;
      }
    }
  }

  int _thumbHeight() =>
      (height * height ~/ _contentHeight.clamp(1, height)).clamp(10, height);

  @override
  void onMouseDrag(int x, int y) {
    if (_dragAxis == 1) {
      final thumbH = _thumbHeight();
      final dragRange = height - thumbH;
      if (dragRange > 0) {
        final delta = y - _dragStartCoord;
        final newOffset = (_dragStartScroll + delta * maxScrollY ~/ dragRange)
            .clamp(0, maxScrollY);
        _controller.jumpTo(newOffset);
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
    _childBox.widget = child;
    child.parent = this;
    // Ensure the child fills the full viewport width (fixes sticky 100px).
    child.performLayout(containerWidth);

    _viewport.layout(
      le.BoxConstraints(
        maxWidth: width.toDouble(),
        maxHeight: height.toDouble(),
      ),
    );

    // Apply initial scroll once extents are known.
    if (_initialScrollY > 0) {
      _controller.jumpTo(_initialScrollY);
      _initialScrollY = 0;
    }

    child.x = x;
    child.y = y;
  }

  @override
  void draw(Painter canvas) {
    if (_viewport.children.isEmpty || _childBox.widget == null) {
      _initScroll();
      _childBox.widget = child;
    }

    // Layout the viewport if dimensions changed.
    if (_viewport.size.width.round() != width ||
        _viewport.size.height.round() != height) {
      _viewport.layout(
        le.BoxConstraints(
          maxWidth: width.toDouble(),
          maxHeight: height.toDouble(),
        ),
      );
    }

    // Apply initial scroll once extents are known (draw path).
    if (_initialScrollY > 0) {
      _controller.jumpTo(_initialScrollY);
      _initialScrollY = 0;
    }

    // Clipped content area.
    canvas.save();
    canvas.clipRect(
      Rect.fromLTWH(
        x.toDouble(),
        y.toDouble(),
        width.toDouble(),
        height.toDouble(),
      ),
    );

    final scrollOff = _controller.offset;
    canvas.translate(0, -scrollOff.toDouble());
    child
      ..x = x
      ..y = y;
    child.draw(canvas);
    canvas.restore();

    // Vertical scrollbar.
    if (showVertical && maxScrollY > 0 && height > 0) {
      final tX = (x + width - scrollbarWidth).toDouble();
      canvas.drawRect(
        Rect.fromLTWH(
          tX,
          y.toDouble(),
          scrollbarWidth.toDouble(),
          height.toDouble(),
        ),
        Paint()..color = scrollbarBg,
      );
      final thumbH = _thumbHeight();
      final thumbY = (_controller.offset * (height - thumbH) ~/ maxScrollY)
          .clamp(0, height - thumbH);
      canvas.drawRect(
        Rect.fromLTWH(
          tX,
          (y + thumbY).toDouble(),
          scrollbarWidth.toDouble(),
          thumbH.toDouble(),
        ),
        Paint()..color = _dragAxis == 1 ? scrollbarHoverColor : scrollbarColor,
      );
    }
  }

  @override
  bool hitTest(int px, int py) {
    if (!super.hitTest(px, py)) return false;
    // Always accept hits within bounds — needed for scroll wheel routing
    // to reach this ScrollArea even when cursor is in empty space between
    // children. Child hit-test is handled separately for click dispatch.
    return true;
  }
}

class _ChildBox extends le.RenderBox {
  Widget? widget;
  _ChildBox(this.widget);

  @override
  void layout(le.BoxConstraints constraints) {
    if (widget == null) return;
    final cw = constraints.hasBoundedWidth ? constraints.maxWidth.round() : 0;
    // Always lay out the child against the viewport width, not the stale
    // widget.width, so resizing the viewport actually grows the content.
    widget!.performLayout(cw);
    size = le.Size(widget!.width.toDouble(), widget!.height.toDouble());
  }
}
