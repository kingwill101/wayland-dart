import 'dart:io' show stderr;

import 'package:window_toolkit/window_toolkit.dart';

import 'metrics.dart';
import 'modules/module.dart';

/// Wraps a [BarModule] for rendering inside the bar.
///
/// Applies waybar-like horizontal padding/margin around the module content.
/// If the module has a [BarModule.widget] set it is drawn/measured/hit-tested
/// through that widget tree instead of the legacy [BarModule.draw] path.
///
/// **Vertical alignment:** content is optically centered in the bar height.
/// Skia [Painter.drawText] is baseline-relative; baseline is computed with
/// [TextLayout] from real glyph bounds (not full font ascent, which sat low).
///
/// **Performance:** [measure] must not call [BarModule.update].
class ModuleWidget extends Widget {
  final BarModule module;

  /// Expose the module's widget tree to toolkit hit-testing and interaction
  /// traversal. The module wrapper is a real tree boundary, not a drawing
  /// shortcut.
  @override
  List<Widget> get children =>
      module.widget == null ? const <Widget>[] : <Widget>[module.widget!];

  Object? _measuredToken;
  int _measuredPadL = -1;
  int _measuredPadR = -1;
  double _measuredContentW = 0;
  late final TextRuns _textRuns = TextRuns('');

  static bool debugLayout = false;
  static bool _debugLogged = false;

  ModuleWidget(this.module) {
    width = 20;
    height = 14;
    styleId = module.name;
    addClass('module');
    addClass(module.name);

    // Every ordinary module owns a toolkit text widget.  Keeping this at the
    // wrapper boundary means modules only publish state (`output`) while the
    // toolkit owns font selection, measurement, clipping, CSS, and drawing.
    // Modules with genuine graphics or their own composite widget opt out.
    if (_canUseToolkitText && module.widget == null) {
      module.widget = _textRuns;
    }
  }

  int get _padL => module.paddingLeft + module.marginLeft;
  int get _padR => module.paddingRight + module.marginRight;

  bool get _canUseToolkitText =>
      !module.showsGraphics && module.name != 'sni' && module.name != 'tray';

  // This is retained for dynamic modules that deliberately clear their
  // widget while unavailable (for example a missing Hyprland IPC socket).
  bool get _usesToolkitText => module.widget == null && _canUseToolkitText;

  void _syncTextRuns(Painter painter, {Color? color}) {
    _textRuns.text = module.output;
    _textRuns.textFont = Font.ui(pixelSize: BarMetrics.current.fontSize);
    _textRuns.iconFont = Font.icon(pixelSize: BarMetrics.current.iconFontSize);
    _textRuns.runSpacing = BarMetrics.current.iconTextGap.toDouble();
    _textRuns.color = color;
    _textRuns.measure(painter);
  }

  void _measureWidget(Painter painter, Widget widget) {
    if (widget is TextRuns) {
      _syncTextRuns(painter);
      widget.measure(painter);
      final content = BarMetrics.current.isIconOutput(module.output)
          ? widget.width.toDouble().clamp(
              BarMetrics.current.iconSlot.toDouble(),
              100000,
            )
          : widget.width.toDouble() + BarMetrics.current.contentFudge;
      width = content.round() + _padL + _padR;
    } else {
      widget.measure(painter);
      width = widget.width + _padL + _padR;
    }
    final barH = painter.height.round();
    height = barH > 0 ? barH : widget.height;
  }

  @override
  void performLayout(int containerWidth) {
    if (height <= 0) height = 14;
  }

  @override
  void measure(Painter painter) {
    if (module.widget != null) {
      _measureWidget(painter, module.widget!);
      return;
    }

    if (_usesToolkitText) {
      _syncTextRuns(painter);
      final measured =
          _textRuns.width.toDouble() + BarMetrics.current.contentFudge;
      _measuredContentW = BarMetrics.current.isIconOutput(module.output)
          ? measured.clamp(BarMetrics.current.iconSlot.toDouble(), 100000)
          : measured;
      width = _measuredContentW.round() + _padL + _padR;
      final barH = painter.height.round();
      height = barH > 0 ? barH : 14;
      return;
    }

    final token = module.layoutToken;
    if (token != _measuredToken ||
        _padL != _measuredPadL ||
        _padR != _measuredPadR) {
      _measuredToken = token;
      _measuredPadL = _padL;
      _measuredPadR = _padR;
      // Every module owns its intrinsic measurement, and the base text path
      // delegates to window_toolkit's shared mixed-font renderer. Graphics
      // modules can override it to include bars/images beyond their label.
      _measuredContentW = module.measure(painter);
    }
    width = _measuredContentW.round() + _padL + _padR;
    final barH = painter.height.round();
    height = barH > 0 ? barH : 14;
  }

  void debugLogLayout() {
    if (!debugLayout || _debugLogged) return;
    stderr.writeln(
      '[layout] ${module.name} x=$x w=$width '
      'content=${_measuredContentW.toStringAsFixed(1)} '
      'padL=$_padL padR=$_padR out="${module.output}"',
    );
  }

  static void debugLayoutDone() {
    if (debugLayout) _debugLogged = true;
  }

  /// Draw-origin y for bar content (Skia blob origin = line top, not baseline).
  double _barTextOriginY(Painter painter, double barH) {
    final font = Font.ui(pixelSize: BarMetrics.current.fontSize);
    final resolved = FontDatabase.instance.resolveRequest(font);
    // Must use Painter.measureTextBounds (shaped blob), not Font.measureText.
    final bounds = painter.measureTextBounds(
      'Hg',
      size: resolved.pixelSize,
      fontFamily: resolved.family,
    );
    return TextLayout.drawOriginForBounds(0, barH, bounds);
  }

  @override
  void draw(Painter painter) {
    // Waybar's Gtk::Label is clipped by its allocated module width.  Keep
    // custom module painters inside the same box so long media/window text,
    // tray icons, and graphics cannot bleed into adjacent modules.
    painter.save();
    painter.clipRect(
      Rect.fromLTWH(x.toDouble(), 0, width.toDouble(), barHeight(painter)),
    );
    try {
      final contentX = (x + _padL).toDouble();
      final barH = painter.height.round().clamp(1, 4096).toDouble();
      height = barH.round();
      y = 0;
      // GTK-like background from CSS (waybar #clock, .module)
      final ctx = StyleContext.forWidget(this);
      final bg = ctx.parsedBackgroundColor;
      if (bg != null && bg.a != 0) {
        painter.drawRect(
          Rect.fromLTWH(x.toDouble(), 0, width.toDouble(), barH),
          Paint()..color = bg,
        );
      }
      final border = ctx.parsedBorderColor;
      if (border != null) {
        painter.drawRect(
          Rect.fromLTWH(x.toDouble(), 0, width.toDouble(), barH),
          Paint()
            ..color = border
            ..style = PaintStyle.stroke
            ..strokeWidth = 1,
        );
      }

      if (module.widget != null) {
        final w = module.widget!;
        if (w is TextRuns) _syncTextRuns(painter, color: ctx.parsedColor);
        w.measure(painter);
        w.x = x + _padL;
        // Center widget tree in the bar (groups, window title, workspaces).
        final wh = w.height > 0 ? w.height : barH.round();
        w.y = ((barH - wh) / 2).round().clamp(0, barH.round());
        if (wh >= barH - 1) {
          w.y = 0;
        }
        w.draw(painter);
      } else {
        // y is Skia text-blob origin (line-box top), centered in the bar.
        final originY = _barTextOriginY(painter, barH);
        final styleFg = ctx.parsedColor;
        // SNI tray draws images via module.draw, not text — never take the CSS text path
        if (module.name == 'sni' || module.name == 'tray') {
          module.cssForeground = null;
          module.draw(painter, contentX, originY);
          return;
        }
        if (_usesToolkitText) {
          _syncTextRuns(painter, color: styleFg);
          _textRuns.x = contentX.round();
          _textRuns.y = 0;
          _textRuns.width = (width - _padL - _padR).clamp(1, width);
          _textRuns.height = barH.round();
          _textRuns.draw(painter);
          return;
        }
        if (module.showsGraphics) {
          // Modules that draw graphs / level bars / images do so in
          // [BarModule.draw]. A CSS foreground must only tint their text —
          // never short-circuit and hide the graph/bar/image.
          module.cssForeground = styleFg;
          module.draw(painter, contentX, originY);
          return;
        }
        if (styleFg != null) {
          // CSS color overrides module's hardcoded _color (waybar style.css).
          painter.drawTextRuns(
            module.output,
            Offset(contentX, originY),
            textFont: Font.ui(pixelSize: BarMetrics.current.fontSize),
            iconFont: Font.icon(pixelSize: BarMetrics.current.iconFontSize),
            color: styleFg,
          );
        } else {
          module.cssForeground = null;
          module.draw(painter, contentX, originY);
        }
      }
    } finally {
      painter.restore();
    }
  }

  double barHeight(Painter painter) =>
      painter.height.round().clamp(1, 4096).toDouble();

  @override
  bool hitTest(int px, int py) {
    final left = x + module.marginLeft;
    final right = x + width - module.marginRight;
    final barH = height > 0 ? height : 30;
    if (px < left || px >= right || py < 0 || py >= barH) {
      return false;
    }
    return true;
  }
}
