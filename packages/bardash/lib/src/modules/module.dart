import 'package:window_toolkit/window_toolkit.dart';

import '../command.dart';
import '../metrics.dart';

abstract class BarModule {
  String get name;

  // ignore: unused_field - stored for subclasses
  Map<String, String> _config = {};
  String format = '';
  String output = '';

  /// Tooltip text shown on hover. Set in [update] or [init].
  String tooltip = '';

  /// Optional tooltip format template (waybar-style `tooltip-format`).
  /// Modules may apply this when building [tooltip].
  String tooltipFormat = '';

  int interval = 5;

  String onClickCmd = '';
  String onClickRightCmd = '';
  String onScrollUpCmd = '';
  String onScrollDownCmd = '';

  /// Horizontal padding around module content (inside hit box).
  /// Defaults come from [BarMetrics.modulePad] — keep low; use bar
  /// [BarMetrics.spacing] for gaps *between* modules.
  int paddingLeft = 0;
  int paddingRight = 0;

  /// Extra outer margin (space outside the hit/padding box).
  int marginLeft = 0;
  int marginRight = 0;

  /// Optional widget tree for this module. When set, [ModuleWidget] uses
  /// it for measuring, drawing, and hit-testing instead of the legacy
  /// [draw] / [measure] / [onClick] methods.
  Widget? widget;

  /// Set by the bar so modules can request an immediate redraw (e.g. SNI
  /// icon changes) without waiting for the poll interval.
  void Function()? requestRepaint;

  void init(Map<String, String> config) {
    _config = config;
    onClickCmd = config['on-click'] ?? '';
    onClickRightCmd = config['on-click-right'] ?? '';
    onScrollUpCmd = config['on-scroll-up'] ?? '';
    onScrollDownCmd = config['on-scroll-down'] ?? '';
    tooltipFormat = config['tooltip-format'] ?? '';

    final m = BarMetrics.current;
    // Density default pad; override with padding / padding-left / padding-right.
    // Prefer asymmetric keys so adjacent modules don't double padR+padL.
    final pad = parseInt(config, 'padding', m.modulePad);
    paddingLeft = parseInt(config, 'padding-left', pad);
    paddingRight = parseInt(config, 'padding-right', pad);
    marginLeft = parseInt(config, 'margin-left', m.moduleMargin);
    marginRight = parseInt(config, 'margin-right', m.moduleMargin);
  }

  Map<String, String> get config => _config;

  void update() {}

  double draw(Painter painter, double x, double y);

  double measure(Painter painter) {
    final m = BarMetrics.current;
    if (m.isIconOutput(output)) return m.iconContentWidth();
    // FontDatabase advance (Qt horizontalAdvance) — not loose ink bounds.
    final w = painter.measureTextFont(
      output,
      Font.ui(pixelSize: m.fontSize),
    );
    return m.textContentWidth(w);
  }

  /// Invalidates [ModuleWidget]'s cached width when this changes.
  /// Defaults to [output]; override when layout depends on more (e.g. tray icons).
  Object get layoutToken => output;

  bool get hasClick => onClickCmd.isNotEmpty;

  /// Left click (button 0x110) or right click (0x111). Coords are module-local.
  void onClick(double x, double y, {int button = 0x110}) {}

  /// Set by the bar on mouse motion when this module is hovered.
  double hoverX = -1;

  /// Optional tooltip anchor in bar coordinates. When >= 0, the bar places
  /// the tip centered on this point instead of the module widget center.
  double tooltipAnchorX = -1;
  double tooltipAnchorY = -1;

  /// Called by the bar after setting [hoverX], before reading [tooltip].
  void prepareHoverTooltip(double moduleX, double moduleY) {}

  /// Called by the bar on scroll wheel events when this module is hovered.
  void onScroll(double delta) {
    if (delta < 0 && onScrollUpCmd.isNotEmpty) {
      runBarCommand(onScrollUpCmd);
    } else if (delta > 0 && onScrollDownCmd.isNotEmpty) {
      runBarCommand(onScrollDownCmd);
    }
  }

  String resolveFormat(
      Map<String, String> config, String defaultFormat, String state) {
    if (state.isNotEmpty && config.containsKey('format-$state')) {
      return config['format-$state']!;
    }
    if (config.containsKey('format')) {
      return config['format']!;
    }
    return defaultFormat;
  }

  /// Apply [tooltipFormat] if set, else return [fallback].
  String resolveTooltip(String fallback, Map<String, String> vars) {
    var tpl = tooltipFormat;
    if (tpl.isEmpty) return fallback;
    vars.forEach((k, v) {
      tpl = tpl.replaceAll('{$k}', v);
    });
    return tpl;
  }

  String getIcon(int value, List<String> icons) {
    if (icons.isEmpty) return '';
    final segment = 100 ~/ icons.length;
    final index = (value / segment).floor().clamp(0, icons.length - 1);
    return icons[index];
  }

  Color parseColor(String hex) {
    hex = hex.replaceFirst('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    final val = int.parse(hex, radix: 16);
    return Color.fromArgb8888(val);
  }

  int parseInt(Map<String, String> config, String key, int defaultVal) {
    return int.tryParse(config[key] ?? '') ?? defaultVal;
  }
}
