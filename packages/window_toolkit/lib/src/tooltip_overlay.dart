/// Layer-shell tooltip for panel / bar surfaces.
///
/// Uses a dedicated `zwlr_layer_shell` surface on the **overlay** layer so the
/// tip stacks above normal windows.
///
/// **Important:** never block on configure from inside a pointer event. Nested
/// `dispatchTimeout` re-enters the Wayland socket and produces
/// `Error waiting for socket data` / broken tips. Mapping is completed from
/// the configure callback instead.
library;

import 'dart:io' show stderr;

import 'package:wayland/wayland.dart';

import 'backend/connection.dart';
import 'backend/layer.dart' show Anchor;
import 'drawing/color.dart';
import 'font/text_layout.dart';
import 'painter/painter.dart';
import 'painter/skia_painter.dart';
import 'painter/skia_text_engine.dart';
import 'palette.dart';
import 'style.dart';
import 'widget.dart';

/// Measurement-only [Painter] used to find a tooltip content widget's
/// intrinsic size before the SHM buffer exists. Text metrics are real (Skia),
/// drawing is a no-op.
class _MeasurePainter implements Painter {
  @override
  double get width => 0;
  @override
  double get height => 0;
  @override
  Size get size => Size.zero();

  @override
  void clear(Color color) {}
  @override
  void drawRect(Rect rect, Paint paint) {}
  @override
  void drawCircle(Offset center, double radius, Paint paint) {}
  @override
  void drawLine(Offset from, Offset to, Paint paint) {}
  @override
  void drawArc(
    Rect oval,
    double startAngle,
    double sweepAngle,
    bool useCenter,
    Paint paint,
  ) {}
  @override
  void drawRRect(Rect rect, double radiusX, double radiusY, Paint paint) {}
  @override
  void drawText(
    String text,
    Offset position, {
    Color? color,
    double size = 14,
    String fontFamily = 'sans',
  }) {}
  @override
  void drawImage(
    String filePath,
    double x,
    double y, {
    double? width,
    double? height,
  }) {}
  @override
  void clipRect(Rect rect) {}
  @override
  void save() {}
  @override
  void restore() {}
  @override
  void translate(double dx, double dy) {}
  @override
  void scale(double sx, double sy) {}
  @override
  void flush() {}
  @override
  void dispose() {}

  @override
  void drawLinearGradient(
    Rect rect,
    Color color0,
    Color color1, {
    double angle = 0.0,
  }) {}
  @override
  Size measureText(
    String text, {
    double size = 14,
    String fontFamily = 'sans',
  }) => SkiaTextEngine.shared.measureText(
    text,
    size: size,
    fontFamily: fontFamily,
  );

  @override
  double measureTextAdvance(
    String text, {
    double size = 14,
    String fontFamily = 'sans',
  }) => SkiaTextEngine.shared.measureTextAdvance(
    text,
    size: size,
    fontFamily: fontFamily,
  );

  @override
  Rect measureTextBounds(
    String text, {
    double size = 14,
    String fontFamily = 'sans',
  }) => SkiaTextEngine.shared.measureTextBounds(
    text,
    size: size,
    fontFamily: fontFamily,
  );
}

class TooltipOverlay {
  final WaylandConnection connection;

  int parentWidth;
  int parentHeight;
  Anchor barAnchor;
  Palette? palette;
  Color? backgroundColor;
  Color? textColor;
  Color? borderColor;
  bool drawBorder;

  double fontSize;
  String fontFamily;
  int paddingHorizontal;
  int paddingVertical;
  int gap;

  /// Optional content widget for this tip. When set, the overlay sizes the
  /// surface to the widget's intrinsic size and lays it out / paints it
  /// through the widget & CSS style system (instead of the default plain-text
  /// [text]).
  Widget? content;

  WlSurface? _surface;
  LayerSurfaceV1? _layer;
  WlSurface? parentSurface;
  WlShmPool? _pool;
  WlBuffer? _buffer;
  int _fd = -1;

  /// SHM / buffer dimensions (may be larger than content).
  int _bufW = 0;
  int _bufH = 0;

  /// Content size last requested of the compositor.
  int _w = 0;
  int _h = 0;

  bool _visible = false;
  bool _configured = false;
  bool _awaitingConfigure = false;
  String _shownText = '';
  int _shownX = 0;
  int _shownY = -9999;

  /// Pending show while waiting for the first configure (non-blocking).
  String? _pendingText;
  int _pendingX = 0;
  int _pendingY = 0;

  TooltipOverlay({
    required this.connection,
    this.parentWidth = 1920,
    this.parentHeight = 30,
    this.barAnchor = Anchor.top,
    this.parentSurface,
    this.palette,
    this.backgroundColor,
    this.textColor,
    this.borderColor,
    this.drawBorder = true,
    this.fontSize = 12,
    this.fontFamily = 'sans',
    this.paddingHorizontal = 10,
    this.paddingVertical = 6,
    this.gap = 0,
    this.content,
  });

  ColorGroup get _colors => (palette ?? Palette.current).forState(true, true);

  Color get resolvedBackground => backgroundColor ?? _colors.tooltipBase;

  Color get resolvedText => textColor ?? _colors.tooltipText;

  Color get resolvedBorder => borderColor ?? _colors.mid;

  int get width => _w;
  int get height => _h;
  bool get isVisible => _visible;

  /// Size for [text] as plain text. Uses Skia metrics when available so
  /// height matches paint (over-tall estimates pushed tips too far from the bar).
  ///
  /// [maxWidth] caps the tip to the output width.
  Size estimateSize(String text, {int? maxWidth}) {
    final lines = text.split('\n');
    final cap = (maxWidth ?? parentWidth).clamp(48, 7680);
    final family = fontFamily == 'sans' ? 'monospace' : fontFamily;

    var maxW = 1.0;
    var totalH = 0.0;
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].isEmpty ? ' ' : lines[i];
      final bounds = SkiaTextEngine.shared.measureTextBounds(
        line,
        size: fontSize,
        fontFamily: family,
      );
      if (bounds.width > maxW) maxW = bounds.width;
      final adv = SkiaTextEngine.shared.measureTextAdvance(
        line,
        size: fontSize,
        fontFamily: family,
      );
      if (adv > maxW) maxW = adv;
      totalH += bounds.height > 0 ? bounds.height : fontSize;
      if (i < lines.length - 1) totalH += fontSize * 0.25;
    }
    final w = (maxW + paddingHorizontal * 2).round().clamp(48, cap);
    final h = (totalH + paddingVertical * 2).round().clamp(18, 480);
    return Size(w.toDouble(), h.toDouble());
  }

  /// Intrinsic size of a [content] widget, including padding. Used to size
  /// the surface for widgets built through the style system.
  Size estimateContent(Widget widget, {int? maxWidth}) {
    final cap = (maxWidth ?? parentWidth).clamp(48, 7680);
    widget.measure(_measurePainter);
    final w = (widget.width + paddingHorizontal * 2).round().clamp(48, cap);
    final h = (widget.height + paddingVertical * 2).round().clamp(18, 480);
    return Size(w.toDouble(), h.toDouble());
  }

  static final _measurePainter = _MeasurePainter();

  /// Show tip at bar-local ([x], [y]). Never blocks the event loop.
  void show(String text, {int x = 0, int y = -24}) {
    if (text.isEmpty) {
      hide();
      return;
    }

    if (_visible && text == _shownText && x == _shownX && y == _shownY) {
      return;
    }

    final shell = connection.layerShell;
    if (shell == null) {
      stderr.writeln('[tooltip] zwlr_layer_shell_v1 not available');
      return;
    }

    final maxTipW = (parentWidth - 8).clamp(48, 7680);
    final estimated = content != null
        ? estimateContent(content!, maxWidth: maxTipW)
        : estimateSize(text, maxWidth: maxTipW);
    final wantW = estimated.width.round().clamp(48, maxTipW);
    final wantH = estimated.height.round();

    // Grow pool if needed; always attach a buffer matching content size
    // (larger buffer + smaller setSize stretches and squishes the tip).
    final needNewPool =
        _surface == null ||
        _layer == null ||
        _pool == null ||
        _bufW < wantW ||
        _bufH < wantH;

    if (needNewPool) {
      _teardownSurface();
      _bufW = wantW;
      _bufH = wantH;
      _w = wantW;
      _h = wantH;
      if (!_createLayer(shell)) {
        destroy();
        return;
      }
    } else {
      _w = wantW;
      _h = wantH;
      _ensureContentBuffer();
    }

    final maxX = (parentWidth - _w).clamp(0, parentWidth);
    x = x.clamp(0, maxX);

    _pendingText = text;
    _pendingX = x;
    _pendingY = y;

    if (!_configured) {
      if (!_awaitingConfigure) {
        _awaitingConfigure = true;
        _applyPlacement(x, y);
        _layer!.setSize(_w, _h);
        _surface!.commit();
      }
      return;
    }

    _commitPending();
  }

  void hide() {
    _pendingText = null;
    if (!_visible && _surface == null) return;

    if (_layer != null && _surface != null && _configured) {
      _layer!.setAnchor(
        LayerSurfaceV1Anchor.top.enumValue |
            LayerSurfaceV1Anchor.left.enumValue,
      );
      _layer!.setMargin(-(_h + 64), 0, 0, 0);
      _layer!.setSize(_w > 0 ? _w : 1, _h > 0 ? _h : 1);
      _layer!.setExclusiveZone(0);
      _surface!.commit();
    }

    _shownX = 0;
    _shownY = -9999;
    _shownText = '';
    _visible = false;
  }

  void destroy() {
    _pendingText = null;
    _teardownSurface();
    _bufW = 0;
    _bufH = 0;
    _w = 0;
    _h = 0;
    _visible = false;
    _shownText = '';
    _shownX = 0;
    _shownY = -9999;
    _configured = false;
    _awaitingConfigure = false;
  }

  // ── Layer surface ───────────────────────────────────────────────

  bool _createLayer(LayerShellV1 shell) {
    _surface = connection.compositor.createSurface().getOrElse((e) {
      stderr.writeln('[tooltip] createSurface: $e');
      return WlSurface(connection.context);
    });

    _layer = shell
        .getLayerSurface(
          _surface!,
          connection.output,
          LayerShellV1Layer.overlay.enumValue,
          'tooltip',
        )
        .getOrElse((e) {
          stderr.writeln('[tooltip] getLayerSurface: $e');
          return LayerSurfaceV1(connection.context);
        });

    _layer!.setSize(_w, _h);
    _layer!.setExclusiveZone(0);
    _layer!.setKeyboardInteractivity(
      LayerSurfaceV1KeyboardInteractivity.none.enumValue,
    );

    final inputRegion = connection.compositor.createRegion().getOrElse((e) {
      stderr.writeln('[tooltip] createRegion: $e');
      return WlRegion(connection.context);
    });
    _surface!.setInputRegion(inputRegion);
    inputRegion.destroy();

    _layer!.onConfigure((e) {
      _layer!.ackConfigure(e.serial);
      _configured = true;
      _awaitingConfigure = false;
      // Complete any show that was waiting without nested dispatch.
      if (_pendingText != null) {
        _commitPending();
      }
    });
    _layer!.onClosed((_) {
      destroy();
    });

    final stride = _bufW * 4;
    final size = stride * _bufH;
    _fd = createAnonymousFile(size);
    if (_fd < 0) return false;
    _pool = connection.shm.createPool(_fd, size).getOrElse((e) {
      stderr.writeln('[tooltip] createPool: $e');
      return WlShmPool(connection.context);
    });
    // Content-sized buffer (may be smaller than pool after shrink).
    _ensureContentBuffer();

    _configured = false;
    _awaitingConfigure = false;
    return true;
  }

  /// wl_buffer must match setSize content dimensions — a larger buffer is
  /// stretched by the compositor and looks "squished".
  void _ensureContentBuffer() {
    if (_pool == null || _fd < 0) return;
    final stride = _w * 4;
    final need = stride * _h;
    if (need > _bufW * _bufH * 4 && _bufW > 0) {
      // Pool too small — caller should have recreated.
      return;
    }
    _buffer?.destroy();
    _buffer = _pool!.createBuffer(0, _w, _h, stride, 0).getOrElse((e) {
      stderr.writeln('[tooltip] createBuffer: $e');
      return WlBuffer(connection.context);
    });
  }

  void _commitPending() {
    final text = _pendingText;
    if (text == null || _surface == null || _layer == null) return;

    var x = _pendingX;
    final y = _pendingY;
    _pendingText = null;

    // Re-clamp in case parentWidth changed.
    final maxX = (parentWidth - _w).clamp(0, parentWidth);
    x = x.clamp(0, maxX);

    // Paint first so buffer is ready before placement commits - positions on top without flicker
    final needPaint = text != _shownText || !_visible;
    if (needPaint) {
      _ensureContentBuffer();
      _paint(text);
      if (_buffer == null || _fd < 0) return;
      _surface!.attach(_buffer!, 0, 0);
      _surface!.damage(0, 0, _w, _h);
    } else {
      _ensureContentBuffer();
    }
    _applyPlacement(x, y);
    _layer!.setSize(_w, _h);
    _layer!.setExclusiveZone(0);

    _surface!.commit();

    _shownText = text;
    _shownX = x;
    _shownY = y;
    _visible = true;
  }

  /// Place the tip next to the bar. Flush on top via layer margins.
  /// Bottom bar: tooltip on top (above bar) via bottomEdge = ph + gap (gap 0 flush).
  /// Top bar: tooltip on top (below bar top edge but still on top layer) via topEdge = ph + gap.
  void _applyPlacement(int parentX, int parentY) {
    if (_layer == null) return;

    final pw = parentWidth.clamp(1, 7680);
    final ph = parentHeight.clamp(1, 4096);
    final maxLeft = (pw - _w).clamp(0, pw);
    final left = parentX.clamp(0, maxLeft);
    final right = (pw - left - _w).clamp(0, pw);
    stderr.writeln(
      '[tooltip] _applyPlacement on-top anchor=$barAnchor ph=$ph gap=$gap left=$left right=$right w=$_w h=$_h parentX=$parentX',
    );

    switch (barAnchor) {
      case Anchor.bottom:
        // On-top: tooltip sits flush on bar top, overlay bottom=gap (exclusiveZone already reserves ph)
        final bottom = gap;
        _placeHorizontal(left, right, bottomEdge: bottom);
      case Anchor.top:
        // On-top: tooltip sits flush below bar, overlay top=gap (exclusiveZone already reserves ph)
        final top = gap;
        _placeHorizontal(left, right, topEdge: top);
      case Anchor.left:
        final maxTop = (ph - _h).clamp(0, ph);
        final top = parentY.clamp(0, maxTop);
        final leftEdge = pw + gap;
        _placeVertical(top, leftEdge: leftEdge);
      case Anchor.right:
        final maxTop = (ph - _h).clamp(0, ph);
        final top = parentY.clamp(0, maxTop);
        final rightEdge = pw + gap;
        _placeVertical(top, rightEdge: rightEdge);
    }
  }

  void _placeHorizontal(int left, int right, {int? topEdge, int? bottomEdge}) {
    // Prefer anchoring to the side with more margin (keeps tip on-screen).
    final preferRight = right <= left;
    if (preferRight) {
      var anchor = LayerSurfaceV1Anchor.right.enumValue;
      if (topEdge != null) {
        anchor |= LayerSurfaceV1Anchor.top.enumValue;
        _layer!.setAnchor(anchor);
        _layer!.setMargin(topEdge, right, 0, 0);
      } else {
        anchor |= LayerSurfaceV1Anchor.bottom.enumValue;
        _layer!.setAnchor(anchor);
        _layer!.setMargin(0, right, bottomEdge ?? 0, 0);
      }
    } else {
      var anchor = LayerSurfaceV1Anchor.left.enumValue;
      if (topEdge != null) {
        anchor |= LayerSurfaceV1Anchor.top.enumValue;
        _layer!.setAnchor(anchor);
        _layer!.setMargin(topEdge, 0, 0, left);
      } else {
        anchor |= LayerSurfaceV1Anchor.bottom.enumValue;
        _layer!.setAnchor(anchor);
        _layer!.setMargin(0, 0, bottomEdge ?? 0, left);
      }
    }
  }

  void _placeVertical(int top, {int? leftEdge, int? rightEdge}) {
    final bottom = (parentHeight - top - _h).clamp(0, 8192);
    final preferBottom = bottom <= top;
    if (preferBottom) {
      var anchor = LayerSurfaceV1Anchor.bottom.enumValue;
      if (leftEdge != null) {
        anchor |= LayerSurfaceV1Anchor.left.enumValue;
        _layer!.setAnchor(anchor);
        _layer!.setMargin(0, 0, bottom, leftEdge);
      } else {
        anchor |= LayerSurfaceV1Anchor.right.enumValue;
        _layer!.setAnchor(anchor);
        _layer!.setMargin(0, rightEdge ?? 0, bottom, 0);
      }
    } else {
      var anchor = LayerSurfaceV1Anchor.top.enumValue;
      if (leftEdge != null) {
        anchor |= LayerSurfaceV1Anchor.left.enumValue;
        _layer!.setAnchor(anchor);
        _layer!.setMargin(top, 0, 0, leftEdge);
      } else {
        anchor |= LayerSurfaceV1Anchor.right.enumValue;
        _layer!.setAnchor(anchor);
        _layer!.setMargin(top, rightEdge ?? 0, 0, 0);
      }
    }
  }

  void _paint(String text) {
    if (_fd < 0 || _buffer == null) return;

    // Resolve tooltip chrome through the single style cascade (provider/CSS
    // addon) with tooltip palette as the role defaults, so tips stay cohesive.
    Color bg = resolvedBackground;
    Color fg = resolvedText;
    Color border = resolvedBorder;
    try {
      final st = _TooltipStyleWidget().resolvedStyle();
      if (st.backgroundColor != null) bg = st.backgroundColor!;
      fg = st.color;
      border = st.borderColor;
    } catch (_) {}

    // Paint at exact content size (matches attached buffer).
    final painter = SkiaPainter(_fd, _w, _h);
    try {
      painter.clear(Color(0, 0, 0, 0));
      painter.drawRRect(
        Rect.fromLTWH(0, 0, _w.toDouble(), _h.toDouble()),
        10,
        10,
        Paint()..color = bg,
      );

      if (drawBorder) {
        painter.drawRRect(
          Rect.fromLTWH(0.5, 0.5, _w - 1.0, _h - 1.0),
          10,
          10,
          Paint()
            ..color = border
            ..style = PaintStyle.stroke
            ..strokeWidth = 1,
        );
      }

      final content = this.content;
      if (content != null) {
        // Lay the styled widget inside the padded box, then draw it through
        // the widget / CSS style system.
        content
          ..x = paddingHorizontal
          ..y = paddingVertical;
        final innerW = (_w - paddingHorizontal * 2).clamp(0, _w);
        content.performLayout(innerW);
        content.draw(painter);
      } else {
        _paintPlainText(painter, text, textColor: fg);
      }
      painter.flush();
    } finally {
      painter.dispose();
    }
  }

  /// Left-aligned plain text, vertically centered within the padded box.
  void _paintPlainText(
    SkiaPainter painter,
    String text, {
    required Color textColor,
  }) {
    final lines = text.split('\n');
    final family = fontFamily == 'sans' ? 'monospace' : fontFamily;

    final lineBounds = <Rect>[];
    var contentH = 0.0;
    for (final raw in lines) {
      final line = raw.isEmpty ? ' ' : raw;
      final bounds = painter.measureTextBounds(
        line,
        size: fontSize,
        fontFamily: family,
      );
      lineBounds.add(bounds);
      final lh = bounds.height > 0 ? bounds.height : fontSize;
      contentH += lh + fontSize * 0.25;
    }

    final availInnerH = (_h - paddingVertical * 2).clamp(0, _h).toDouble();
    var yCursor =
        paddingVertical.toDouble() +
        (availInnerH > contentH ? (availInnerH - contentH) / 2.0 : 0.0);

    for (var i = 0; i < lines.length; i++) {
      final rawLine = lines[i].isEmpty ? ' ' : lines[i];
      final bounds = lineBounds[i];
      final lh = bounds.height > 0 ? bounds.height : fontSize;
      final originY = TextLayout.baselineForBounds(
        yCursor,
        lh.toDouble(),
        bounds,
      );
      final xOff = paddingHorizontal.toDouble() - bounds.left;
      painter.drawText(
        rawLine,
        Offset(xOff, originY),
        color: textColor,
        size: fontSize,
        fontFamily: family,
      );
      yCursor += lh + fontSize * 0.25;
    }
  }

  void _teardownSurface() {
    _buffer?.destroy();
    _buffer = null;
    _pool?.destroy();
    _pool = null;
    if (_fd >= 0) {
      closeFd(_fd);
      _fd = -1;
    }
    _layer?.destroy();
    _layer = null;
    _surface?.destroy();
    _surface = null;
    _configured = false;
    _awaitingConfigure = false;
  }
}

class _TooltipStyleWidget extends Widget {
  _TooltipStyleWidget() {
    styleId = 'tooltip';
    addClass('tooltip');
  }

  /// Tooltip role defaults from the palette (CSS/provider overrides on top).
  @override
  Style styleRole() => Style(
    color: palette.tooltipText,
    backgroundColor: palette.tooltipBase,
    borderColor: palette.tooltipText,
    borderRadius: 10,
  );

  @override
  void performLayout(int containerWidth) {}
  @override
  void draw(Painter canvas) {}
}
