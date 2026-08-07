import 'dart:async' show scheduleMicrotask;
import 'dart:io';

import 'package:window_toolkit/window_toolkit.dart';

import 'command.dart';
import 'config.dart';
import 'module_widget.dart';
import 'modules/group.dart';
import 'skia_mem.dart';
import 'modules/module.dart';
import 'modules/registry.dart';
import 'modules/sni.dart';
import 'tray_menu.dart';

class _ModuleEntry {
  final Align align;
  final ModuleWidget widget;
  final BarModule module;
  _ModuleEntry(this.align, this.widget, this.module);
}

class BardashBar extends LayerWindow {
  final BardashConfig config;
  final Container _layout = Container();
  final List<Timer> _timers = [];
  final List<_ModuleEntry> _entries = [];
  _ModuleEntry? _hovered;
  TooltipOverlay? _tooltip;
  /// Last tip text we passed to [TooltipOverlay.show] (null when hidden).
  String? _activeTip;
  /// Last tray/icon anchor x used for placement (-1 when N/A).
  int _activeAnchorX = -1;
  /// Coalesce timer-driven paints (many modules share 1–5s intervals).
  bool _paintScheduled = false;

  BardashBar(this.config)
    : super(
        anchor: config.anchor,
        barHeight: config.height,
        exclusiveZone: config.exclusiveZone,
        namespace: 'bardash',
      ) {
    stderr.writeln('[bardash] Bar created anchor=${config.anchor} height=${config.height}');
    // Ensure density tokens are active even if config was built without
    // fromLua (tests / programmatic construction).
    config.applyMetrics();
    // GTK-like styling: window#waybar + provider for screen (like waybar Client::setupCss)
    // LayerWindow is not a Widget; put waybar id on the root Container so
    // window#waybar descendant rules still match (#waybar, #pulseaudio etc).
    _layout.styleId = 'waybar';
    _layout.addClass('waybar');
    _setupCss();
    ModuleWidget.debugLayout =
        Platform.environment['BARDASH_DEBUG_LAYOUT'] == '1';
    _layout.spacing = config.spacing;
    _buildLayout();
    stderr.writeln('[bardash] Bar layout built, ${_entries.length} modules');

    // Load CSS reload helper after build (watches style file)
    _initCssReload();

    // Cap Skia font cache at 8 MB to keep RSS bounded.
    // Default is often 128+ MB on desktop Linux.
    skiaSetFontCacheLimit(8 * 1024 * 1024);

    // Periodic Skia cache cleanup — bar text labels change rarely so
    // the shaped-text cache accumulates stale entries over hours.
    _timers.add(EventLoop.instance.addTimer(
      const Duration(seconds: 120),
      _memoryHousekeeping,
    ));
  }

  void _memoryHousekeeping() {
    try {
      final rss = ProcessInfo.currentRss;
      final fontUsed = skiaFontCacheUsed();
      final fontLimit = skiaFontCacheLimit();
      stderr.writeln('[bardash] mem: rss=${rss ~/ 1024}KB skia_font_cache=${(fontUsed ~/ 1024)}KB/${(fontLimit ~/ 1024)}KB');
      purgeSkiaCaches();
    } catch (e) {
      stderr.writeln('[bardash] mem housekeeping error: $e');
    }
  }

  void _buildLayout() {
    for (final list in [
      config.modulesLeft, config.modulesCenter, config.modulesRight,
    ]) {
      for (final name in list) {
        final module = createModule(name);
        if (module == null) continue;
        final modCfg = <String, String>{
          'icon-font-family': config.iconFontFamily,
        };
        if (config.moduleConfigs.containsKey(name)) {
          for (final entry in config.moduleConfigs[name]!.entries) {
            if (entry.value is String) modCfg[entry.key] = entry.value as String;
          }
        }
        // Groups need the full config map so children get their own blocks.
        if (module is GroupModule) {
          module.bindFactory(
            allModuleConfigs: config.moduleConfigs,
            iconFontFamily: config.iconFontFamily,
          );
        }
        module.init(modCfg);
        // Async modules (SNI tray, …) can force a redraw when data changes.
        module.requestRepaint = schedulePaint;
        final widget = ModuleWidget(module);
        // GTK-like: waybar adds "module" + id classes for #pulseaudio etc.
        widget.styleId = name;
        widget.addClass('module');
        widget.addClass(name);
        // Also tag Align wrapper so descendant selectors can match
        final align = Align(
          child: widget,
          horizontalAlignment: HorizontalAlignment.left,
          verticalAlignment: VerticalAlignment.center,
        )..styleId = '${name}_align'
         ..addClass('module-align');
        // Keep style ancestry: widget.parent = align already via layout, but set now for StyleContext
        widget.parent = align;
        if (list == config.modulesLeft) {
          align.addClass('modules-left');
          _layout.left.add(align);
        } else if (list == config.modulesCenter) {
          align.addClass('modules-center');
          _layout.center.add(align);
        } else {
          align.addClass('modules-right');
          _layout.right.add(align);
        }
        _entries.add(_ModuleEntry(align, widget, module));
        if (module.interval > 0) {
          _timers.add(EventLoop.instance.addTimer(Duration(seconds: module.interval), () {
            final before = module.output;
            module.update();
            // Refresh tip text if this module is still hovered.
            if (_hovered?.module == module &&
                _activeTip != null &&
                !TrayMenuController.isOpen) {
              final tip = module.tooltip;
              if (tip.isNotEmpty && tip != _activeTip) {
                _showTooltipFor(_hovered!, tip);
              } else if (tip.isEmpty) {
                _dismissTooltip();
              }
            }
            // Async modules (wireplumber/network/mpd) call requestRepaint
            // themselves when data changes. Only paint here for sync updates.
            if (module.output != before) {
              schedulePaint();
            }
          }));
        }
      }
    }
  }

  (_ModuleEntry?, Widget?) _hitTestDeep(int px, int py) {
    for (int i = _entries.length - 1; i >= 0; i--) {
      final e = _entries[i];
      if (!e.align.hitTest(px, py)) continue;
      final mw = e.module.widget;
      if (mw != null) {
        mw.x = e.widget.x; mw.y = e.widget.y;
        if (mw.hitTest(px, py)) return (e, _deepestHit(mw, px, py));
      }
      return (e, null);
    }
    return (null, null);
  }

  Widget? _deepestHit(Widget w, int px, int py) {
    Widget? best = w.hitTest(px, py) ? w : null;
    if (w is HBox) {
      for (final child in w.children) {
        final sub = _deepestHit(child, px, py);
        if (sub != null) best = sub;
      }
    }
    return best;
  }

  /// One paint per microtask turn — module timers often fire together.
  void schedulePaint() {
    if (_paintScheduled) return;
    _paintScheduled = true;
    scheduleMicrotask(() {
      _paintScheduled = false;
      paint();
    });
  }

  void _dismissTooltip() {
    _activeTip = null;
    _activeAnchorX = -1;
    _tooltip?.hide();
  }

  /// Place tip relative to the module, not the cursor — stable while hovering.
  ///
  /// Positions are clamped to the bar surface so edge modules (tray icons,
  /// battery, etc.) do not push the tip off-screen ("swish" / cut off).
  void _showTooltipFor(_ModuleEntry entry, String tip) {
    // Never compete with an open tray context menu.
    if (TrayMenuController.isOpen) {
      _dismissTooltip();
      return;
    }

    _tooltip ??= TooltipOverlay(
      connection: connection,
      parentWidth: width,
      parentHeight: height,
      barAnchor: config.anchor,
      gap: 0,
      parentSurface: surface,
    );
    // Keep geometry in sync (configure / resize).
    _tooltip!.parentWidth = width;
    _tooltip!.parentHeight = height;
    _tooltip!.barAnchor = config.anchor;
    _tooltip!.gap = 0;
    _tooltip!.parentSurface = surface;

    // Cap tip to bar width so edge modules (tray) never overflow the output.
    final size =
        _tooltip!.estimateSize(tip, maxWidth: (width - 8).clamp(48, width));
    final tw = size.width.round();
    final th = size.height.round();
    const edgePad = 4;

    // Prefer a per-icon anchor when the module set one (e.g. SNI tray).
    final anchorX = entry.module.tooltipAnchorX >= 0
        ? entry.module.tooltipAnchorX.round()
        : entry.widget.x + entry.widget.width ~/ 2;
    final anchorY = entry.module.tooltipAnchorY >= 0
        ? entry.module.tooltipAnchorY.round()
        : entry.widget.y + entry.widget.height ~/ 2;

    // Horizontal: center on anchor, clamp on-screen.
    // Vertical for top/bottom bars is decided inside TooltipOverlay from
    // parentHeight + gap (do not pass tipY = -th - gap — that double-counted
    // height and sat tips too far from the bar).
    var tipX = anchorX - tw ~/ 2;
    var tipY = anchorY; // used for left/right bars only
    switch (config.anchor) {
      case Anchor.top:
      case Anchor.bottom:
        final maxX = (width - tw - edgePad).clamp(edgePad, width);
        tipX = tipX.clamp(edgePad, maxX);
        tipY = 0;
      case Anchor.left:
      case Anchor.right:
        final maxY = (height - th - edgePad).clamp(edgePad, height);
        tipY = (anchorY - th ~/ 2).clamp(edgePad, maxY);
        tipX = 0;
    }

    _activeTip = tip;
    _tooltip!.show(tip, x: tipX, y: tipY);
  }

  void _updateHover(int px, int py) {
    final prev = _hovered;
    if (prev != null) {
      prev.widget.removePseudoClass('hover');
      prev.widget.removeClass('hover');
    }
    if (prev != null) prev.module.hoverX = -1;
    final (hit, _) = _hitTestDeep(px, py);

    // Left every module (gap in bar or empty space).
    if (hit == null) {
      if (_hovered != null || _activeTip != null) {
        _hovered = null;
        _dismissTooltip();
      }
      return;
    }
    // GTK-like :hover (waybar #pulseaudio:hover)
    hit.widget.addPseudoClass('hover');
    hit.widget.addClass('hover');

    hit.module.hoverX = px.toDouble();
    // Let multi-icon modules (tray) resolve tip text + icon anchor now.
    hit.module.prepareHoverTooltip(
      hit.widget.x.toDouble(),
      hit.widget.y.toDouble(),
    );

    // Tray context menu owns the pointer UX — keep tips hidden.
    if (TrayMenuController.isOpen) {
      _hovered = hit;
      _dismissTooltip();
      return;
    }

    final tip = hit.module.tooltip;
    if (tip.isEmpty) {
      _hovered = hit;
      _dismissTooltip();
      return;
    }

    // Re-show when tray icon (anchor) changes even if title text matches.
    final anchorKey = hit.module.tooltipAnchorX.round();
    if (hit == _hovered &&
        tip == _activeTip &&
        (_tooltip?.isVisible ?? false) &&
        _activeAnchorX == anchorKey) {
      return;
    }

    _hovered = hit;
    _activeAnchorX = anchorKey;
    _showTooltipFor(hit, tip);
  }

  @override
  void onMouseMotion(MouseMotionEvent event) =>
      _updateHover(event.x.toInt(), event.y.toInt());

  @override
  void onMouseEnter(MouseEnterEvent event) =>
      _updateHover(event.x.toInt(), event.y.toInt());

  @override
  void onMouseLeave(MouseLeaveEvent event) {
    _hovered?.module.hoverX = -1;
    _hovered = null;
    _dismissTooltip();
  }

  @override
  void onMouseButtonPressed(MouseButtonEvent event) {
    final (entry, hitWidget) = _hitTestDeep(event.x.toInt(), event.y.toInt());

    // Never show tooltips while interacting with buttons (esp. right-click menus).
    _dismissTooltip();
    _activeTip = null;

    // Clicks on empty bar dismiss an open tray menu.
    // Desktop clicks are handled by the menu's full-output dismiss layer.
    if (entry == null) {
      if (TrayMenuController.isOpen) TrayMenuController.close();
      return;
    }
    if (event.button != 0x110 && event.button != 0x111) return;

    // Module-local coordinates for multi-icon modules (tray, etc.).
    final localX = event.x - entry.widget.x;
    final localY = event.y - entry.widget.y;

    if (hitWidget?.onClick != null && event.button == 0x110) {
      hitWidget!.onClick!.call();
    } else {
      // Absolute X for groups / tray (set before onClick so hit-tests work).
      entry.module.hoverX = event.x.toDouble();
      entry.module.onClick(localX, localY, button: event.button);
      // Right-click command on the *entry* module (not used for groups —
      // children handle their own on-click-right via onClick above).
      if (event.button == 0x111 &&
          entry.module is! GroupModule &&
          entry.module.onClickRightCmd.isNotEmpty) {
        runBarCommand(entry.module.onClickRightCmd);
      }
    }
    entry.module.update();
    // Don't paint immediately on right-click — paint can race with menu map.
    if (event.button != 0x111) {
      paint();
    }
  }

  @override
  void onMouseWheel(MouseWheelEvent event) {
    // Ensure hover is current even if motion was missed.
    _updateHover(event.x.toInt(), event.y.toInt());
    final target = _hovered?.module;
    if (target == null) return;
    target.onScroll(event.dy);
    // Refresh tip if volume text changed under cursor.
    if (_activeTip != null &&
        target.tooltip.isNotEmpty &&
        !TrayMenuController.isOpen) {
      _showTooltipFor(_hovered!, target.tooltip);
    }
    paint();
  }

  CssProvider? _cssProvider;
  CssReloadHelper? _cssReloader;

  void _setupCss() {
    final path = _resolveCssPath();
    if (path == null) return;
    try {
      final provider = CssProvider();
      final ok = provider.loadFromPath(path);
      if (ok) {
        StyleContext.addProviderForScreen(provider, priority: StyleProviderPriority.user);
        _cssProvider = provider;
        stderr.writeln('[bardash] CSS loaded $path (${provider.rules.length} rules)');
      }
    } catch (e) {
      stderr.writeln('[bardash] CSS load failed $path: $e');
    }
  }

  void _initCssReload() {
    final path = _resolveCssPath();
    if (path == null || _cssProvider == null) return;
    try {
      _cssReloader = CssReloadHelper(_cssProvider!, path: path, onReload: (ok) {
        stderr.writeln('[bardash] CSS reloaded $path ok=$ok');
        schedulePaint();
      })..start();
    } catch (_) {}
  }

  String? _resolveCssPath() {
    final explicit = config.stylePath;
    if (explicit != null) {
      final expanded = explicit.replaceFirst('~', Platform.environment['HOME'] ?? '');
      return expanded;
    }
    final home = Platform.environment['HOME'] ?? '';
    for (final p in [
      '$home/.config/bardash/style.css',
      '$home/.config/bardash/style.scss',
      '$home/.config/waybar/style.css',
      '$home/.config/waybar/style.scss',
    ]) {
      if (File(p).existsSync()) return p;
    }
    return null;
  }

  @override
  void draw(Painter painter) {
    stderr.writeln('[bardash] draw() painter=$painter size=${painter.width.round()}x${painter.height.round()}');
    // Wire tray module to the live layer surface for dbusmenu popups.
    for (final e in _entries) {
      if (e.module is SniModule) {
        (e.module as SniModule).attach(
          connection,
          surface,
          parentWidth: width,
          parentHeight: height,
          // Bottom bar → open menu upward into the screen.
          openUpward: config.anchor == Anchor.bottom,
        );
      }
    }

    // CSS background for window#waybar overrides config (Skia/Gles/Raw all via Painter)
    final styleBg = StyleContext.forWidget(_layout).parsedBackgroundColor;
    final bg = styleBg ?? config.backgroundColor;
    stderr.writeln('[bardash] clearing with bg=$bg (style ${styleBg != null ? "CSS" : "config"})');
    painter.clear(bg);
    _layout.x = 0;
    _layout.y = 0;
    _layout.width = painter.width.round();
    _layout.height = painter.height.round();
    stderr.writeln('[bardash] layout: ${_layout.width}x${_layout.height}');
    _layout.draw(painter);
    if (ModuleWidget.debugLayout) {
      for (final e in _entries) {
        e.widget.debugLogLayout();
      }
      ModuleWidget.debugLayoutDone();
    }
    stderr.writeln('[bardash] draw complete');
  }
}
