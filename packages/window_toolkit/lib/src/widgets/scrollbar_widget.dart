/// Scrollbar widget built on [le.ScrollbarMetrics].
///
/// Renders a vertical scrollbar track and thumb, supports drag scrolling
/// and hover highlighting.
library;

import 'package:layout_engine/layout_engine.dart' as le;

import '../animation/animation_controller.dart';
import '../animation/curves.dart';
import '../drawing/color.dart';
import '../event_loop.dart';
import '../mixins/event.dart';
import '../painter/painter.dart';
import '../widget.dart';

/// A vertical scrollbar that tracks a [le.ScrollController].
///
/// Renders a track and thumb, supports drag-to-scroll, click-to-page,
/// and animated thumb. Typically overlaid on or placed next to a viewport.
///
/// ```dart
/// final ctrl = ViewportScrollController();
/// Scrollbar(controller: ctrl, viewportHeight: 300)
/// ```
class Scrollbar extends Widget {
  le.ScrollController controller;
  int thickness;
  int viewportHeight = 0;
  final Color? trackColor;
  final Color? thumbColor;
  final Color? hoverColor;
  bool hovered = false;
  bool _dragging = false;
  int _dragStartScroll = 0;
  int _dragStartY = 0;

  Scrollbar({
    required this.controller,
    this.thickness = 6,
    int viewportHeight = 0,
    this.trackColor,
    this.thumbColor,
    this.hoverColor,
  }) {
    this.viewportHeight = viewportHeight;
  }

  Color get _trackColor => trackColor ?? palette.mid;
  Color get _thumbColor => _dragging
      ? (hoverColor ?? palette.windowText)
      : (hovered ? (hoverColor ?? palette.light) : (thumbColor ?? palette.light));
  Color get _hoverTrackColor => trackColor ?? palette.mid;

  le.ScrollbarMetrics _computeMetrics() {
    final trackH = viewportHeight > 0 ? viewportHeight.toDouble() : height.toDouble();
    return le.ScrollbarMetrics.from(controller, trackH);
  }

  @override
  void draw(Painter canvas) {
    final metrics = _computeMetrics();
    if (!metrics.visible) return;

    final xPos = (x + width - thickness).toDouble();
    final yPos = y.toDouble();
    final trackH = metrics.trackSize;

    // Track
    canvas.drawRect(
      Rect.fromLTWH(xPos, yPos, thickness.toDouble(), trackH),
      Paint()..color = _trackColor,
    );

    // Thumb
    final thumbY = yPos + metrics.thumbOffset;
    canvas.drawRect(
      Rect.fromLTWH(xPos, thumbY, thickness.toDouble(), metrics.thumbSize),
      Paint()..color = _thumbColor,
    );
  }

  @override
  bool onMouseWheel(MouseWheelEvent event) {
    controller.scrollBy(event.dy.round());
    return true;
  }

  @override
  void onMouseDown(int x, int y, int button) {
    if (button != 272) return;
    final metrics = _computeMetrics();
    if (!metrics.visible) return;

    final sbx = this.x + width - thickness;
    if (x < sbx || x >= sbx + thickness || y < this.y || y >= this.y + metrics.trackSize.round()) return;

    final thumbStart = (this.y + metrics.thumbOffset).round();
    final thumbEnd = (thumbStart + metrics.thumbSize).round();

    if (y >= thumbStart && y < thumbEnd) {
      _dragging = true;
      _dragStartScroll = controller.offset;
      _dragStartY = y;
    } else {
      // Page up/down
      final step = y < thumbStart ? -viewportHeight : viewportHeight;
      controller.scrollBy(step);
    }
  }

  @override
  void onMouseUp(int x, int y, int button) {
    _dragging = false;
  }

  @override
  void onMouseDrag(int x, int y) {
    if (!_dragging) return;
    final metrics = _computeMetrics();
    if (!metrics.visible) return;
    final dragRange = (metrics.trackSize - metrics.thumbSize).round();
    if (dragRange <= 0) return;
    final delta = y - _dragStartY;
    final newOffset = (_dragStartScroll + delta * controller.maxOffset ~/ dragRange)
        .clamp(0, controller.maxOffset);
    controller.jumpTo(newOffset);
  }

  @override
  bool hitTest(int px, int py) {
    final metrics = _computeMetrics();
    if (!metrics.visible) return false;
    return px >= x && px < x + width && py >= y && py < y + metrics.trackSize.round();
  }
}
