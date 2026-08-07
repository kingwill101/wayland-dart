/// GTK-like `StyleContext` — resolves `CssProvider` declarations for a `Widget`.
///
/// Waybar pattern:
/// ```cpp
/// window.get_style_context()->add_class("modules-left");
/// label.get_style_context()->add_class("module");
/// label.get_style_context()->add_class(id); // e.g. "pulseaudio"
/// // later: css_provider->load_from_path(...); add_provider_for_screen(..., USER);
/// ```
/// We mirror that with `Widget.styleId/styleClasses/pseudoClasses` + a
/// global provider list ordered by priority (last `USER` wins), and a
/// per-widget resolver that handles id/class/type/descendant selectors.
library;

import '../drawing/color.dart';
import '../widget.dart';
import 'css_provider.dart';

class _ProviderEntry {
  final CssProvider provider;
  final int priority;
  _ProviderEntry(this.provider, this.priority);
}

class StyleContext {
  static final List<_ProviderEntry> _providers = [];

  /// Mirrors `Gtk::StyleContext::add_provider_for_screen(screen, provider, priority)`.
  static void addProviderForScreen(CssProvider provider, {int priority = StyleProviderPriority.user}) {
    _providers.add(_ProviderEntry(provider, priority));
    // Stable priority ordering — higher priority wins (last checked first).
    _providers.sort((a, b) => a.priority.compareTo(b.priority));
  }

  static void removeProviderForScreen(CssProvider provider) {
    _providers.removeWhere((e) => identical(e.provider, provider));
  }

  static void removeProvider(CssProvider provider) => removeProviderForScreen(provider);

  /// For testing — clears all providers.
  static void reset() => _providers.clear();

  static List<CssProvider> get providers => List.unmodifiable(_providers.map((e) => e.provider));

  final Widget widget;
  final List<Widget> ancestry; // root ... widget

  StyleContext._(this.widget, this.ancestry);

  /// Build a context for [widget]. If [ancestry] is not supplied, it falls
  /// back to the single-widget chain (no descendant matching). Callers that
  /// have a parent pointer should build the full chain themselves.
  factory StyleContext.forWidget(Widget widget, {List<Widget>? ancestry}) {
    final chain = ancestry ?? _chainFromParents(widget);
    return StyleContext._(widget, chain);
  }

  static List<Widget> _chainFromParents(Widget w) {
    final chain = <Widget>[];
    Widget? cur = w;
    // Walk via `parent` if widgets have linked parents; otherwise just [w].
    while (cur != null) {
      chain.insert(0, cur);
      cur = cur.parent;
    }
    if (chain.isEmpty) chain.add(w);
    return chain;
  }

  /// All properties resolved for this widget, with proper cascading.
  Map<String, String> get allProperties {
    final result = <String, _Prop>{};
    // Providers are sorted low->high; iterate low->high so higher can override,
    // but within equal priority respect specificity and source order.
    final entries = List<_ProviderEntry>.from(_providers);
    for (final entry in entries) {
      for (final rule in entry.provider.rules) {
        for (final sel in rule.selectors) {
          if (!_matchesSelector(sel, ancestry)) continue;
          for (final kv in rule.declarations.entries) {
            final key = kv.key;
            final existing = result[key];
            final candidate = _Prop(kv.value, rule.specificity, rule.sourceOrder, entry.priority);
            if (existing == null || candidate.winsOver(existing)) {
              result[key] = candidate;
            }
          }
        }
      }
    }
    return result.map((k, v) => MapEntry(k, v.value));
  }

  String? getProperty(String name) => allProperties[name.toLowerCase()];

  String? get color => getProperty('color');
  String? get backgroundColor => getProperty('background-color') ?? getProperty('background');
  String? get borderColor => getProperty('border-color');

  Color? get parsedColor => _parseCssColor(color);
  Color? get parsedBackgroundColor => _parseCssColor(backgroundColor);
  Color? get parsedBorderColor => _parseCssColor(borderColor);

  // GTK-style helpers used by waybar modules.
  bool hasClass(String cls) => widget.hasClass(cls);
}

Color? _parseCssColor(String? value) {
  if (value == null) return null;
  var v = value.trim().toLowerCase();
  if (v.isEmpty || v == 'transparent' || v == 'none') return const Color(0, 0, 0, 0);
  // hex: #rgb, #rrggbb, #rrggbbaa
  if (v.startsWith('#')) {
    var hex = v.substring(1);
    if (hex.length == 3) hex = hex.split('').map((c) => '$c$c').join();
    if (hex.length == 6) hex = 'ff$hex';
    if (hex.length == 8) {
      final a = int.tryParse(hex.substring(0, 2), radix: 16) ?? 255;
      final r = int.tryParse(hex.substring(2, 4), radix: 16) ?? 0;
      final g = int.tryParse(hex.substring(4, 6), radix: 16) ?? 0;
      final b = int.tryParse(hex.substring(6, 8), radix: 16) ?? 0;
      return Color(r, g, b, a);
    }
  }
  // rgb/rgba
  final rgba = RegExp(r'rgba?\s*\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*(?:,\s*([0-9.]+))?\s*\)').firstMatch(v);
  if (rgba != null) {
    final r = int.parse(rgba.group(1)!).clamp(0, 255);
    final g = int.parse(rgba.group(2)!).clamp(0, 255);
    final b = int.parse(rgba.group(3)!).clamp(0, 255);
    var a = 255;
    if (rgba.group(4) != null) {
      final af = double.tryParse(rgba.group(4)!) ?? 1.0;
      a = (af <= 1 ? (af * 255).round() : af.round()).clamp(0, 255);
    }
    return Color(r, g, b, a);
  }
  return null;
}

class _Prop {
  final String value;
  final int specificity;
  final int order;
  final int priority;
  _Prop(this.value, this.specificity, this.order, this.priority);

  bool winsOver(_Prop other) {
    if (priority != other.priority) return priority > other.priority;
    if (specificity != other.specificity) return specificity > other.specificity;
    return order > other.order;
  }
}

/// Matching helpers — handles:
/// `window#waybar`, `#pulseaudio`, `.module`, `button:hover`,
/// `#workspaces button`, `window#waybar.hidden`
bool _matchesSelector(String selector, List<Widget> chain) {
  final parts = selector.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
  if (parts.isEmpty) return false;
  // Last part must match the target widget; earlier parts must match ancestors in order.
  var chainIdx = chain.length - 1;
  var partIdx = parts.length - 1;
  // Match target
  if (!_matchesSimple(parts[partIdx], chain[chainIdx])) return false;
  partIdx--;
  chainIdx--;
  while (partIdx >= 0) {
    var found = false;
    while (chainIdx >= 0) {
      if (_matchesSimple(parts[partIdx], chain[chainIdx])) {
        found = true;
        chainIdx--;
        break;
      }
      chainIdx--;
    }
    if (!found) return false;
    partIdx--;
  }
  return true;
}

bool _matchesSimple(String part, Widget w) {
  // Split pseudo and class/id/type combined, e.g. "window#waybar.hidden:hover"
  // Extract ids, classes, pseudos, and optional type.
  final ids = RegExp(r'#([a-zA-Z0-9_-]+)').allMatches(part).map((m) => m.group(1)!).toList();
  final classes = RegExp(r'\.([a-zA-Z0-9_-]+)').allMatches(part).map((m) => m.group(1)!).toList();
  final pseudos = RegExp(r':([a-zA-Z0-9_-]+)').allMatches(part).map((m) => m.group(1)!).toList();
  final typeMatch = RegExp(r'^([a-zA-Z][a-zA-Z0-9_-]*)').firstMatch(part);
  final type = typeMatch?.group(1);

  if (type != null && type != '*' && type != 'window') {
    final wType = _widgetTypeName(w);
    if (wType != type && wType.toLowerCase() != type.toLowerCase()) return false;
  }
  if (type == 'window' || type == '*') {
    // GTK window is the bar surface — treat as wildcard for toolkit.
  }
  for (final id in ids) {
    if (w.styleId != id) return false;
  }
  for (final cls in classes) {
    if (!w.hasClass(cls)) return false;
  }
  for (final pseudo in pseudos) {
    if (!w.hasPseudoClass(pseudo)) return false;
  }
  return true;
}

String _widgetTypeName(Widget w) {
  // Use runtime type name lowercased, e.g. Label -> "label", but waybar uses
  // "window" for the top bar — callers set that via styleId/styleClasses anyway.
  // We also map common toolkit names: Label/button are not in waybar CSS,
  // so they match by class/id instead of type.
  return w.runtimeType.toString().toLowerCase();
}
