import 'dart:io' show stderr;

import 'package:window_toolkit/window_toolkit.dart';

import 'bar_text.dart';
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

  Object? _measuredToken;
  int _measuredPadL = -1;
  int _measuredPadR = -1;
  double _measuredContentW = 0;

  static bool debugLayout = false;
  static bool _debugLogged = false;

  ModuleWidget(this.module) {
    width = 20;
    height = 14;
    styleId = module.name;
    addClass('module');
    addClass(module.name);
  }

  int get _padL => module.paddingLeft + module.marginLeft;
  int get _padR => module.paddingRight + module.marginRight;

  @override
  void performLayout(int containerWidth) {
    if (height <= 0) height = 14;
  }

  @override
  void measure(Painter painter) {
    if (module.widget != null) {
      module.widget!.measure(painter);
      width = module.widget!.width + _padL + _padR;
      final barH = painter.height.round();
      height = barH > 0 ? barH : module.widget!.height;
      return;
    }

    final token = module.layoutToken;
    if (token != _measuredToken ||
        _padL != _measuredPadL ||
        _padR != _measuredPadR) {
      _measuredToken = token;
      _measuredPadL = _padL;
      _measuredPadR = _padR;
      // Ensure PUA icons (power) get icon font width even if module forgot.
      if (BarText.hasIconGlyphs(module.output)) {
        _measuredContentW = BarText.measure(painter, module.output);
      } else {
        _measuredContentW = module.measure(painter);
      }
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
      if (styleFg != null) {
        // CSS color overrides module's hardcoded _color (waybar style.css).
        // Use BarText.fontFor so PUA icons (power) get Hack Nerd Font, not sans.
        final font = BarText.fontFor(module.output);
        painter.drawTextFont(module.output, Offset(contentX, originY), font: font, color: styleFg);
      } else {
        // Even without CSS, ensure PUA gets icon font for measure/draw consistency.
        if (BarText.hasIconGlyphs(module.output)) {
          final f = BarText.iconFont();
          painter.drawTextFont(module.output, Offset(contentX, originY), font: f);
          return;
        }
        module.draw(painter, contentX, originY);
      }
    }
  }

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
