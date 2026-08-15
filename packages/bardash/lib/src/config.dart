import 'dart:io';

import 'package:lualike/lualike.dart';
import 'package:window_toolkit/window_toolkit.dart';

import 'metrics.dart';

/// A reference to a Lua function defined in the config file.
///
/// Keeps the Lua runtime alive so the function can be called on every poll
/// tick instead of running a shell command.
class LuaExecFunc {
  final Value function;
  final LuaRuntime runtime;
  LuaExecFunc(this.function, this.runtime);

  /// Call the Lua function and return its result as a string.
  Future<String> call() async {
    final result = await runtime.callFunction(function, []);
    if (result is Value) return result.unwrap().toString();
    return result?.toString() ?? '';
  }
}

class BardashConfig {
  Anchor anchor = Anchor.top;
  int height = 30;
  int exclusiveZone = 30;

  /// Gap between top-level modules (see [BarMetrics.spacing]).
  int spacing = 2;
  String iconFontFamily = 'Hack Nerd Font';
  Color backgroundColor = const Color(30, 30, 30);

  /// GTK-like CSS — mirrors waybar `style.css` (CssProvider load_from_path).
  /// Null → check `~/.config/bardash/style.css` then `~/.config/waybar/style.css`.
  String? stylePath;

  /// Layout density scale; drives defaults for spacing / pad / icon sizes.
  BarMetrics metrics = BarMetrics.normal;
  List<String> modulesLeft = [];
  List<String> modulesCenter = [];
  List<String> modulesRight = [];

  /// Per-module config.  Each value is a map from config key (dashed form
  /// like `on-click`) to either a [String] or [LuaExecFunc].
  final Map<String, Map<String, Object>> moduleConfigs = {};

  /// Keep the Lua VM alive so function references remain callable.
  /// Look up a Lua function executor for [moduleName]'s [key].
  LuaExecFunc? luaExecFunc(String moduleName, String key) {
    final cfg = moduleConfigs[moduleName];
    if (cfg == null) return null;
    final v = cfg[key];
    if (v is LuaExecFunc) return v;
    return null;
  }

  /// Install [metrics] as the process-wide [BarMetrics.current] and sync
  /// [FontDatabase] role families (Qt-style app font settings).
  void applyMetrics() {
    BarMetrics.current = metrics;
    // window_toolkit font manager: UI + icon roles used by measure/draw.
    FontDatabase.instance.defaultPixelSize = metrics.fontSize;
    FontDatabase.instance.setRoleFamily(FontRole.ui, 'sans');
    FontDatabase.instance.setRoleFamily(FontRole.icon, iconFontFamily);
    FontDatabase.instance.setRoleFamily(FontRole.mono, 'monospace');
    // Emoji family is used directly by battery / volume modules.
    // Use Skia with default font manager + cache limits before registering
    // the icon face. Registering first would attach the font to the engine
    // that is immediately discarded by useSkiaEngine().
    // The 8 MB font cache cap + periodic purge keep RSS bounded.
    try {
      FontDatabase.instance.useSkiaEngine();
      // Try to register icon font file if present on system (like Waybar's
      // FontAwesome/Nerd requirement). Mirrors Waybar's Pango fallback scan.
      _tryRegisterIconFont(iconFontFamily);
    } catch (_) {
      // Tests / headless may only have bitmap.
    }
  }

  static void _tryRegisterIconFont(String family) {
    const candidates = [
      '/usr/share/fonts/TTF/HackNerdFont-Regular.ttf',
      '/usr/share/fonts/TTF/Hack NF.ttf',
      '/usr/share/fonts/OTF/HackNerdFont-Regular.otf',
      '/usr/share/fonts/TTF/Font Awesome 6 Free-Solid-900.otf',
      '/usr/share/fonts/OTF/FontAwesome.otf',
      '/usr/share/fonts/truetype/font-awesome/fontawesome-webfont.ttf',
      '/usr/share/fonts/TTF/NerdFonts/Hack/HackNerdFont-Regular.ttf',
    ];
    for (final path in candidates) {
      final f = File(path);
      if (f.existsSync()) {
        try {
          FontDatabase.instance.addApplicationFont(path);
          break;
        } catch (_) {}
      }
    }
    // Also try family-named lookup — if already installed, no file needed.
  }

  static Future<BardashConfig> fromLua(String source) async {
    final lua = LuaLike();
    await lua.execute(source);
    final config = BardashConfig();

    final position = lua.getGlobal('position');
    if (position is Value) {
      final unwrapped = position.unwrap();
      if (unwrapped == 'bottom') {
        config.anchor = Anchor.bottom;
      } else if (unwrapped == 'top') {
        config.anchor = Anchor.top;
      }
    }

    // Density first so height/spacing defaults can come from the scale when
    // the user only sets `density = "compact"`.
    var heightSet = false;
    var zoneSet = false;
    var spacingSet = false;

    final densityVal = lua.getGlobal('density');
    if (densityVal is Value && densityVal.unwrap() != null) {
      config.metrics = BarMetrics.fromName(densityVal.unwrap().toString());
    }

    final h = lua.getGlobal('height');
    if (h is Value && h.unwrap() is num) {
      config.height = (h.unwrap() as num).toInt();
      heightSet = true;
    }

    final z = lua.getGlobal('exclusive_zone');
    if (z is Value && z.unwrap() is num) {
      config.exclusiveZone = (z.unwrap() as num).toInt();
      zoneSet = true;
    }

    final s = lua.getGlobal('spacing');
    if (s is Value && s.unwrap() is num) {
      config.spacing = (s.unwrap() as num).toInt();
      spacingSet = true;
    }

    // Fill unset bar geometry from density.
    if (!heightSet) config.height = config.metrics.barHeight;
    if (!zoneSet) config.exclusiveZone = config.height;
    if (!spacingSet) config.spacing = config.metrics.spacing;

    final iconFontFamily = lua.getGlobal('icon_font_family');
    if (iconFontFamily is Value && iconFontFamily.unwrap() is String) {
      config.iconFontFamily = iconFontFamily.unwrap() as String;
    }

    final styleVal = lua.getGlobal('style');
    if (styleVal is Value && styleVal.unwrap() is String) {
      final s = (styleVal.unwrap() as String).trim();
      if (s.isNotEmpty) config.stylePath = s;
    }

    config.modulesLeft = _readTableList(lua.getGlobal('modules_left'));
    config.modulesCenter = _readTableList(lua.getGlobal('modules_center'));
    config.modulesRight = _readTableList(lua.getGlobal('modules_right'));

    // Per-module config (like waybar's JSON blocks)
    final modConfigs = lua.getGlobal('modules_config');
    if (modConfigs is Value && modConfigs.isTable) {
      final unwrapped = modConfigs.unwrap();
      if (unwrapped is Map) {
        for (final entry in unwrapped.entries) {
          final modName = entry.key.toString();
          final modTable = entry.value;
          if (modTable is Map) {
            final cfg = <String, Object>{};
            for (final kv in modTable.entries) {
              final key = kv.key.toString().replaceAll('_', '-');
              final raw = kv.value;
              if (raw is Value && raw.isFunction) {
                cfg[key] = LuaExecFunc(raw, lua.vm);
              } else {
                cfg[key] = raw.toString();
              }
            }
            config.moduleConfigs[modName] = cfg;
          }
        }
      }
    }

    config.applyMetrics();
    return config;
  }

  static List<String> _readTableList(Object? value) {
    if (value is! Value || !value.isTable) return [];
    final unwrapped = value.unwrap();
    if (unwrapped is List) {
      return unwrapped.map((e) => e.toString()).toList();
    }
    if (unwrapped is Map) {
      final result = <String>[];
      for (var i = 1; ; i++) {
        final entry = unwrapped[i];
        if (entry == null) break;
        result.add(entry.toString());
      }
      return result;
    }
    return [];
  }

  static Future<BardashConfig> fromFile(String path) async {
    final source = await File(path).readAsString();
    return fromLua(source);
  }
}
