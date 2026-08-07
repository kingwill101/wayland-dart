/// GTK-like CSS provider for window_toolkit.
///
/// Mirrors `Gtk::CssProvider` + `Gtk::StyleContext::add_provider_for_screen`.
///
/// ```dart
/// // Load once (like waybar Client::setupCss):
/// final provider = CssProvider();
/// provider.loadFromPath('/etc/xdg/waybar/style.css');
/// StyleContext.addProviderForScreen(provider, priority: StyleProviderPriority.user);
///
/// // SCSS is also accepted — compiled via `package:sass` first:
/// provider.loadFromData(r'$bg: #2b303b; window#waybar { background: $bg; }', isScss: true);
/// ```
library;

import 'dart:io';

import 'package:csslib/parser.dart' as css;
import 'package:csslib/visitor.dart';
import 'package:sass/sass.dart' as sass;

/// Priority ordering — matches `GTK_STYLE_PROVIDER_PRIORITY_*`.
/// Larger value wins. `user` is what waybar uses.
class StyleProviderPriority {
  static const int fallback = 1;
  static const int theme = 200;
  static const int settings = 400;
  static const int application = 600;
  static const int user = 800;
}

/// A single CSS rule after parsing.
class CssRule {
  final List<String> selectors; // raw selector text, e.g. "window#waybar", "#pulseaudio:hover"
  final Map<String, String> declarations; // property -> raw value
  final int specificity;
  final int sourceOrder;
  CssRule({
    required this.selectors,
    required this.declarations,
    required this.specificity,
    required this.sourceOrder,
  });
}

/// Parses CSS (or SCSS compiled to CSS) via `package:csslib` and exposes
/// declarations grouped by selector. Supports ids (`#id`), classes (`.cls`),
/// element names (`window`, `button`), pseudo-classes (`:hover`, `:active`,
/// `.hidden`), and descendant combinators (`#workspaces button`).
class CssProvider {
  final List<CssRule> _rules = [];
  int _orderCounter = 0;
  String _rawCss = '';

  List<CssRule> get rules => List.unmodifiable(_rules);
  String get rawCss => _rawCss;

  bool loadFromData(String cssText, {bool isScss = false}) {
    final cssToParse = isScss ? _compileScss(cssText) : cssText;
    _rawCss = cssToParse;
    return _parse(cssToParse);
  }

  bool loadFromPath(String path, {bool isScss = false}) {
    final file = File(path);
    if (!file.existsSync()) return false;
    final text = file.readAsStringSync();
    final wantsScss = isScss || path.endsWith('.scss');
    return loadFromData(text, isScss: wantsScss);
  }

  /// `Gtk::CssProvider::load_from_path` returns bool — we keep the same.
  bool loadFromString(String cssText) => loadFromData(cssText);

  String _compileScss(String scss) {
    try {
      return sass.compileString(scss);
    } catch (_) {
      // Fall back to raw if sass fails — let csslib try to parse what it can.
      return scss;
    }
  }

  bool _parse(String cssText) {
    _rules.clear();
    if (cssText.trim().isEmpty) return true;
    final errors = <css.Message>[];
    final StyleSheet sheet = css.parse(cssText, errors: errors);
    // Even with errors, csslib still emits usable tree — collect what we can.
    for (final node in sheet.topLevels) {
      if (node is RuleSet) {
        final decls = <String, String>{};
        final declGroup = node.declarationGroup;
        for (final decl in declGroup.declarations) {
          if (decl is Declaration) {
            final prop = decl.property;
            // Full value via span text after colon to preserve rgba(), etc.
            final spanText = decl.span.text ?? '';
            final colon = spanText.indexOf(':');
            String value = '';
            if (colon >= 0) {
              value = spanText.substring(colon + 1).replaceAll(';', '').trim();
              // Fallback to expression span if split failed
              if (value.isEmpty) value = decl.expression?.span?.text.trim() ?? '';
            } else {
              value = decl.expression?.span?.text.trim() ?? '';
            }
            if (prop.isNotEmpty && value.isNotEmpty) decls[prop.toLowerCase()] = value;
          }
        }
        if (decls.isEmpty) continue;
        final selectors = <String>[];
        final selGroup = node.selectorGroup;
        if (selGroup == null) continue;
        for (final group in selGroup.selectors) {
          final text = group.span?.text.trim() ?? '';
          if (text.isEmpty) continue;
          // csslib may emit one entry per comma-separated selector, but also
          // keep commas in span — split to be safe.
          for (final part in text.split(',')) {
            final p = part.trim();
            if (p.isNotEmpty) selectors.add(p);
          }
        }
        if (selectors.isEmpty) continue;
        final spec = selectors.map(_specificityOf).fold<int>(0, (a, b) => a > b ? a : b);
        _rules.add(CssRule(
          selectors: selectors,
          declarations: decls,
          specificity: spec,
          sourceOrder: _orderCounter++,
        ));
      }
    }
    return errors.isEmpty;
  }

  static int _specificityOf(String selector) {
    // Simplified CSS specificity: id=100, class/pseudo=10, element=1
    var a = 0, b = 0, c = 0;
    // Split descendant combinators
    for (final part in selector.split(RegExp(r'\s+'))) {
      if (part.isEmpty) continue;
      // Count ids
      a += '#'.allMatches(part).length;
      // Classes and pseudo-classes (including ".hidden" and ":hover")
      b += '.'.allMatches(part).length;
      b += ':'.allMatches(part).length;
      // Element name at start (e.g. "window" in "window#waybar")
      if (RegExp(r'^[a-zA-Z]').hasMatch(part)) c += 1;
    }
    return a * 100 + b * 10 + c;
  }
}
