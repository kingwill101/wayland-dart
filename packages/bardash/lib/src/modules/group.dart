import 'package:window_toolkit/window_toolkit.dart';

import '../metrics.dart';
import '../module_widget.dart';
import 'module.dart';
import 'registry.dart';
import 'separator.dart';

/// Horizontal group of child modules (inspired by waybar `group/*`).
///
/// Config example (Lua):
/// ```lua
/// modules_right = { "group/sys", "clock", "sni" }
/// modules_config = {
///   ["group/sys"] = {
///     modules = "cpu,memory,battery",
///     separator = " · ",
///     padding = "6",
///     background = "#2a2a2a",
///   },
///   cpu = { format = "{usage}%" },
/// }
/// ```
class GroupModule extends BarModule {
  GroupModule(this._groupName);

  final String _groupName;
  final List<BarModule> _contentChildren = [];
  final List<BarModule> _allChildren = [];
  String _separator = ' · ';
  Color? _background;
  Map<String, Map<String, Object>> _allConfigs = {};
  String _iconFontFamily = 'Noto Color Emoji';

  @override
  String get name => _groupName;

  List<BarModule> get contentChildren => List.unmodifiable(_contentChildren);

  /// Wire shared config maps so children receive their own module blocks.
  void bindFactory({
    required Map<String, Map<String, Object>> allModuleConfigs,
    required String iconFontFamily,
  }) {
    _allConfigs = allModuleConfigs;
    _iconFontFamily = iconFontFamily;
  }

  @override
  void init(Map<String, String> config) {
    final withDefaults = Map<String, String>.from(config);
    // Groups add no outer pad by default; children stay tight.
    withDefaults.putIfAbsent('padding', () => '0');
    super.init(withDefaults);
    interval = parseInt(config, 'interval', 1);
    // Empty string allowed; default middle-dot only when key omitted entirely.
    _separator = config.containsKey('separator')
        ? (config['separator'] ?? '')
        : ' · ';
    if (config.containsKey('background')) {
      _background = parseColor(config['background']!);
    }

    _contentChildren.clear();
    final raw = config['modules'] ?? '';
    final names = raw
        .split(RegExp(r'[\s,]+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty);

    // Default child pad 0 — inter-icon gap comes from HBox [spacing]
    // (groupChildPad / config `spacing` or `item-spacing`).
    final childPad = config['child-padding'] ?? '0';

    for (final childName in names) {
      final child = createModule(childName);
      if (child == null) continue;
      final childCfg = <String, String>{'icon-font-family': _iconFontFamily};
      final block = _allConfigs[childName];
      if (block != null) {
        for (final e in block.entries) {
          if (e.value is String) childCfg[e.key] = e.value as String;
        }
      }
      // Only apply group child-padding if the child did not set its own.
      childCfg.putIfAbsent('padding', () => childPad);
      child.init(childCfg);
      _contentChildren.add(child);
    }

    _rebuildWidget(config);
  }

  void _rebuildWidget([Map<String, String>? config]) {
    _allChildren.clear();
    final boxChildren = <Widget>[];

    for (var i = 0; i < _contentChildren.length; i++) {
      if (i > 0 && _separator.isNotEmpty) {
        final sep = SeparatorModule();
        sep.init({'format': _separator, 'padding': '0', 'color': '#787878'});
        _allChildren.add(sep);
        boxChildren.add(ModuleWidget(sep));
      }
      _allChildren.add(_contentChildren[i]);
      boxChildren.add(ModuleWidget(_contentChildren[i]));
    }

    // Item gap: item-spacing > spacing > density groupChildPad.
    final cfg = config ?? this.config;
    final itemSpacing = parseInt(
      cfg,
      'item-spacing',
      parseInt(cfg, 'spacing', BarMetrics.current.groupChildPad),
    );

    widget = _GroupBox(
      background: _background,
      child: HBox(spacing: itemSpacing, children: boxChildren),
    );
  }

  @override
  void update() {
    for (final c in _contentChildren) {
      c.update();
    }
  }

  @override
  double draw(Painter painter, double x, double y) => 0;

  @override
  double measure(Painter painter) {
    widget?.measure(painter);
    return (widget?.width ?? 0).toDouble();
  }

  @override
  void prepareHoverTooltip(double moduleX, double moduleY) {
    // [hoverX] is absolute bar X (set by BardashBar).
    final child = _childAtAbsolute(hoverX);
    if (child == null || child is SeparatorModule) {
      tooltip = '';
      tooltipAnchorX = -1;
      tooltipAnchorY = -1;
      return;
    }
    child.hoverX = hoverX;
    final childWidget = _moduleWidgetFor(child);
    final cx = childWidget?.x.toDouble() ?? moduleX;
    final cy = childWidget?.y.toDouble() ?? moduleY;
    child.prepareHoverTooltip(cx, cy);
    // Prefer child's own tip, else its tooltip-format / static tooltip.
    final tip = child.tooltip.isNotEmpty
        ? child.tooltip
        : (child.tooltipFormat.isNotEmpty ? child.tooltipFormat : '');
    tooltip = tip;
    tooltipAnchorX = child.tooltipAnchorX >= 0 ? child.tooltipAnchorX : hoverX;
    tooltipAnchorY = child.tooltipAnchorY >= 0 ? child.tooltipAnchorY : cy + 8;
  }

  @override
  void onClick(double x, double y, {int button = 0x110}) {
    // Bar passes *module-local* x (event.x - groupWidget.x), but child
    // ModuleWidgets store *absolute* x after layout/draw. Use absolute
    // [hoverX] (set by the bar right before this call) for hit-testing.
    final absX = hoverX >= 0 ? hoverX : x;
    final child = _childAtAbsolute(absX);
    if (child == null || child is SeparatorModule) return;

    // Delegate to the child once (CustomModule runs on-click itself).
    // Pass coords relative to the child widget for any multi-zone modules.
    final childWidget = _moduleWidgetFor(child);
    final localX = childWidget != null ? absX - childWidget.x : absX;
    final localY = y;
    child.hoverX = absX;
    child.onClick(localX, localY, button: button);
  }

  @override
  void onScroll(double delta) {
    final child = _childAtAbsolute(hoverX);
    if (child == null || child is SeparatorModule) return;
    child.onScroll(delta);
  }

  ModuleWidget? _moduleWidgetFor(BarModule module) {
    if (widget is! _GroupBox) return null;
    final box = (widget as _GroupBox).child;
    if (box is! HBox) return null;
    for (final w in box.children) {
      if (w is ModuleWidget && identical(w.module, module)) return w;
    }
    return null;
  }

  /// Hit-test children using **absolute** bar X coordinates.
  ///
  /// After paint, HBox children have absolute [Widget.x]. The bar's
  /// module-local click coords must not be compared to those directly.
  BarModule? _childAtAbsolute(double absolutePx) {
    if (widget is! _GroupBox) return null;
    final box = (widget as _GroupBox).child;
    if (box is! HBox) return null;

    // Re-layout from the group's content origin so x values are absolute.
    final originX = widget!.x;
    final originY = widget!.y;
    box
      ..x = originX
      ..y = originY
      ..layout(box.width, box.height);

    for (final w in box.children) {
      if (w is ModuleWidget &&
          absolutePx >= w.x &&
          absolutePx < w.x + w.width) {
        return w.module;
      }
    }
    return null;
  }
}

class _GroupBox extends DecoratedBox {
  _GroupBox({Color? background, required Widget child})
    : super(color: background, child: child);
}
