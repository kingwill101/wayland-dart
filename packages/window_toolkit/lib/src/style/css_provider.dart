/// CSS provider for the toolkit's general style system.
///
/// This is **the CSS addon**: it parses CSS (optionally SCSS) into the same
/// typed [StylePatch] model every other [StyleProvider] contributes to, and
/// is registered with `StyleContext.addProviderForScreen`. Because it speaks
/// the general model, CSS plays nicely alongside (and can override with a
/// higher priority than) programmatic / theme providers.
///
/// Mirrors `Gtk::CssProvider` + `Gtk::StyleContext::add_provider_for_screen`.
/// Supported properties follow the GTK3 CSS property catalog — see
/// `docs/style-system.md` for the full list. Highlights:
///
/// - colors: `color`, `background-color`, `border-*-color`, `outline-color`,
///   hex / `rgb()` / `rgba()` / named / `@define-color` symbolic colors
/// - font: `font-family`, `font-size`, `font-style`, `font-weight`,
///   `font-variant`, `font` shorthand, `letter-spacing`
/// - box: `padding` (+ sides), `margin` (+ sides), `min-width`, `min-height`
/// - borders: `border-width/style/color` (+ sides), `border` / `border-top` …
///   shorthands, `border-radius` (+ corners)
/// - outline: `outline-style/width/color`
/// - background: `background-color`, `background` shorthand, `box-shadow`
/// - opacity, `text-decoration`
library;

import 'dart:io';

import 'package:csslib/parser.dart' as css;
import 'package:csslib/visitor.dart';
import 'package:sass/sass.dart' as sass;

import '../drawing/color.dart';
import '../widget.dart';
import 'style_provider.dart';
import 'style_patch.dart';

/// A single CSS rule after parsing.
class CssRule {
  final List<String>
  selectors; // raw selector text, e.g. "window#waybar", "#pulseaudio:hover"
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
class CssProvider extends StyleProvider {
  final List<CssRule> _rules = [];
  final Map<String, Color> _namedColors = {}; // @define-color
  int _orderCounter = 0;
  String _rawCss = '';

  List<CssRule> get rules => List.unmodifiable(_rules);
  String get rawCss => _rawCss;

  CssProvider({super.priority});

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
    _namedColors.clear();
    if (cssText.trim().isEmpty) return true;
    final errors = <css.Message>[];
    final StyleSheet sheet = css.parse(cssText, errors: errors);

    for (final node in sheet.topLevels) {
      if (node is VarDefinitionDirective) {
        // @define-color bg_color #f9a039;  →  name/value from span text
        final text = node.span.text;
        final parts = text.split(RegExp(r'\s+'));
        if (parts.length >= 3) {
          final name = parts[1].replaceAll(RegExp(r'^@|;$'), '');
          final value = parts.sublist(2).join(' ').replaceAll(';', '').trim();
          final c = _parseCssColor(value);
          if (name.isNotEmpty && c != null) _namedColors[name] = c;
        }
        continue;
      }
      if (node is! RuleSet) continue;
      final decls = <String, String>{};
      final declGroup = node.declarationGroup;
      for (final decl in declGroup.declarations) {
        if (decl is Declaration) {
          final prop = decl.property;
          // Full value via span text after colon to preserve rgba(), etc.
          final spanText = decl.span.text;
          final colon = spanText.indexOf(':');
          String value = '';
          if (colon >= 0) {
            value = spanText.substring(colon + 1).replaceAll(';', '').trim();
            // Fallback to expression span if split failed
            if (value.isEmpty) value = decl.expression?.span?.text.trim() ?? '';
          } else {
            value = decl.expression?.span?.text.trim() ?? '';
          }
          if (prop.isNotEmpty && value.isNotEmpty)
            decls[prop.toLowerCase()] = value;
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
      final spec = selectors
          .map(_specificityOf)
          .fold<int>(0, (a, b) => a > b ? a : b);
      _rules.add(
        CssRule(
          selectors: selectors,
          declarations: decls,
          specificity: spec,
          sourceOrder: _orderCounter++,
        ),
      );
    }
    return errors.isEmpty;
  }

  static int _specificityOf(String selector) {
    // Simplified CSS specificity: id=100, class/pseudo=10, element=1
    var a = 0, b = 0, c = 0;
    for (final part in selector.split(RegExp(r'\s+'))) {
      if (part.isEmpty) continue;
      a += '#'.allMatches(part).length;
      b += '.'.allMatches(part).length;
      b += ':'.allMatches(part).length;
      if (RegExp(r'^[a-zA-Z]').hasMatch(part)) c += 1;
    }
    return a * 100 + b * 10 + c;
  }

  // ── StyleProvider implementation ─────────────────────────────────────────

  @override
  StylePatch styleFor(Widget widget, List<Widget> chain) {
    final matched =
        _rules
            .where((r) => r.selectors.any((s) => _matchesSelector(s, chain)))
            .toList()
          ..sort((a, b) {
            final bySpec = b.specificity.compareTo(a.specificity);
            return bySpec != 0
                ? bySpec
                : b.sourceOrder.compareTo(a.sourceOrder);
          });

    var resolved = StylePatch.empty;
    for (final rule in matched) {
      // Highest specificity/order comes first; fill gaps so it wins.
      resolved = resolved.fillFrom(_styleFromDecls(rule.declarations));
    }
    return resolved;
  }

  /// Map CSS declaration strings onto typed [StylePatch] properties.
  StylePatch _styleFromDecls(Map<String, String> decls) {
    Color? color;
    double? opacity;
    String? fontFamily;
    double? fontSize;
    TextStyle? fontStyle;
    int? fontWeight;
    bool? smallCaps;
    double? letterSpacing;
    TextDecoration? decoration;
    Color? decorationColor;

    int? mLeft, mTop, mRight, mBottom;
    double? minWidth, minHeight;

    Color? bg;
    double? shX, shY, shBlur;
    Color? shColor;

    int? pLeft, pTop, pRight, pBottom;

    double? bwTop, bwRight, bwBottom, bwLeft;
    BorderStyle? bsTop, bsRight, bsBottom, bsLeft;
    Color? bcTop, bcRight, bcBottom, bcLeft;
    double? rTL, rTR, rBR, rBL;

    Color? oc;
    double? ow;
    BorderStyle? os;

    decls.forEach((prop, raw) {
      final v = raw.trim();
      switch (prop) {
        // ── color ──────────────────────────────────────────────
        case 'color':
          final c = _parseCssColor(v);
          if (c != null) color = c;
        case 'opacity':
          opacity = _number(v) ?? opacity;

        // ── font ───────────────────────────────────────────────
        case 'font-family':
          fontFamily = _fontFamily(v) ?? fontFamily;
        case 'font-size':
          fontSize = _length(v) ?? fontSize;
        case 'font-style':
          if (v == 'italic' || v == 'oblique')
            fontStyle = TextStyle.italic;
          else if (v == 'normal')
            fontStyle = TextStyle.normal;
        case 'font-weight':
          fontWeight = _fontWeight(v) ?? fontWeight;
        case 'font-variant':
          if (v == 'small-caps') smallCaps = true;
        case 'letter-spacing':
          letterSpacing = _length(v) ?? letterSpacing;
        case 'text-decoration':
          final deco = _textDecoration(v);
          decoration = deco.line ?? decoration;
          decorationColor = deco.color ?? decorationColor;
        case 'text-decoration-line':
          decoration = _textDecorationLine(v) ?? decoration;
        case 'text-decoration-color':
          decorationColor = _parseCssColor(v) ?? decorationColor;

        // ── box ────────────────────────────────────────────────
        case 'margin':
          final m = _four(v, _length);
          mTop = m.top?.toInt() ?? mTop;
          mRight = m.right?.toInt() ?? mRight;
          mBottom = m.bottom?.toInt() ?? mBottom;
          mLeft = m.left?.toInt() ?? mLeft;
        case 'margin-top':
          mTop = _length(v)?.toInt() ?? mTop;
        case 'margin-right':
          mRight = _length(v)?.toInt() ?? mRight;
        case 'margin-bottom':
          mBottom = _length(v)?.toInt() ?? mBottom;
        case 'margin-left':
          mLeft = _length(v)?.toInt() ?? mLeft;
        case 'min-width':
          minWidth = _length(v) ?? minWidth;
        case 'min-height':
          minHeight = _length(v) ?? minHeight;

        // ── padding ────────────────────────────────────────────
        case 'padding':
          final p = _four(v, _length);
          pTop = p.top?.toInt() ?? pTop;
          pRight = p.right?.toInt() ?? pRight;
          pBottom = p.bottom?.toInt() ?? pBottom;
          pLeft = p.left?.toInt() ?? pLeft;
        case 'padding-top':
          pTop = _length(v)?.toInt() ?? pTop;
        case 'padding-right':
          pRight = _length(v)?.toInt() ?? pRight;
        case 'padding-bottom':
          pBottom = _length(v)?.toInt() ?? pBottom;
        case 'padding-left':
          pLeft = _length(v)?.toInt() ?? pLeft;

        // ── background ─────────────────────────────────────────
        case 'background' || 'background-color':
          final c = _parseCssColor(v);
          if (c != null) bg = c;
        case 'box-shadow':
          final s = _boxShadow(v);
          if (s != null) {
            shX = s.x ?? shX;
            shY = s.y ?? shY;
            shBlur = s.blur ?? shBlur;
            shColor = s.color ?? shColor;
          }

        // ── border shorthands ─────────────────────────────────
        case 'border':
          final b = _borderSide(v);
          bwTop = b.width ?? bwTop;
          bwRight = b.width ?? bwRight;
          bwBottom = b.width ?? bwBottom;
          bwLeft = b.width ?? bwLeft;
          bsTop = b.style ?? bsTop;
          bsRight = b.style ?? bsRight;
          bsBottom = b.style ?? bsBottom;
          bsLeft = b.style ?? bsLeft;
          bcTop = b.color ?? bcTop;
          bcRight = b.color ?? bcRight;
          bcBottom = b.color ?? bcBottom;
          bcLeft = b.color ?? bcLeft;
        case 'border-width':
          final w = _four(v, _length);
          bwTop = w.top ?? bwTop;
          bwRight = w.right ?? bwRight;
          bwBottom = w.bottom ?? bwBottom;
          bwLeft = w.left ?? bwLeft;
        case 'border-style':
          final s = _four(v, BorderStyle.parse);
          bsTop = s.top ?? bsTop;
          bsRight = s.right ?? bsRight;
          bsBottom = s.bottom ?? bsBottom;
          bsLeft = s.left ?? bsLeft;
        case 'border-color':
          final c = _four(v, _parseCssColor);
          bcTop = c.top ?? bcTop;
          bcRight = c.right ?? bcRight;
          bcBottom = c.bottom ?? bcBottom;
          bcLeft = c.left ?? bcLeft;
        case 'border-top':
          final b = _borderSide(v);
          bwTop = b.width ?? bwTop;
          bsTop = b.style ?? bsTop;
          bcTop = b.color ?? bcTop;
        case 'border-right':
          final b = _borderSide(v);
          bwRight = b.width ?? bwRight;
          bsRight = b.style ?? bsRight;
          bcRight = b.color ?? bcRight;
        case 'border-bottom':
          final b = _borderSide(v);
          bwBottom = b.width ?? bwBottom;
          bsBottom = b.style ?? bsBottom;
          bcBottom = b.color ?? bcBottom;
        case 'border-left':
          final b = _borderSide(v);
          bwLeft = b.width ?? bwLeft;
          bsLeft = b.style ?? bsLeft;
          bcLeft = b.color ?? bcLeft;
        case 'border-top-width':
          bwTop = _length(v) ?? bwTop;
        case 'border-right-width':
          bwRight = _length(v) ?? bwRight;
        case 'border-bottom-width':
          bwBottom = _length(v) ?? bwBottom;
        case 'border-left-width':
          bwLeft = _length(v) ?? bwLeft;
        case 'border-top-style':
          bsTop = BorderStyle.parse(v) ?? bsTop;
        case 'border-right-style':
          bsRight = BorderStyle.parse(v) ?? bsRight;
        case 'border-bottom-style':
          bsBottom = BorderStyle.parse(v) ?? bsBottom;
        case 'border-left-style':
          bsLeft = BorderStyle.parse(v) ?? bsLeft;
        case 'border-top-color':
          bcTop = _parseCssColor(v) ?? bcTop;
        case 'border-right-color':
          bcRight = _parseCssColor(v) ?? bcRight;
        case 'border-bottom-color':
          bcBottom = _parseCssColor(v) ?? bcBottom;
        case 'border-left-color':
          bcLeft = _parseCssColor(v) ?? bcLeft;

        // ── border radius ─────────────────────────────────────
        case 'border-radius':
          final r = _four(v, _length);
          rTL = r.top ?? rTL;
          rTR = r.right ?? rTR;
          rBR = r.bottom ?? rBR;
          rBL = r.left ?? rBL;
        case 'border-top-left-radius':
          rTL = _length(v) ?? rTL;
        case 'border-top-right-radius':
          rTR = _length(v) ?? rTR;
        case 'border-bottom-right-radius':
          rBR = _length(v) ?? rBR;
        case 'border-bottom-left-radius':
          rBL = _length(v) ?? rBL;

        // ── outline ───────────────────────────────────────────
        case 'outline':
          final b = _borderSide(v);
          ow = b.width ?? ow;
          os = b.style ?? os;
          oc = b.color ?? oc;
        case 'outline-width':
          ow = _length(v) ?? ow;
        case 'outline-style':
          os = BorderStyle.parse(v) ?? os;
        case 'outline-color':
          oc = _parseCssColor(v) ?? oc;

        // ── font shorthand (GTK supports it) ──────────────────
        case 'font':
          final f = _fontShorthand(v);
          if (f != null) {
            fontStyle = f.style ?? fontStyle;
            fontWeight = f.weight ?? fontWeight;
            fontSize = f.size ?? fontSize;
            fontFamily = f.family ?? fontFamily;
          }
      }
    });

    return StylePatch(
      color: color,
      opacity: opacity,
      fontFamily: fontFamily,
      fontSize: fontSize,
      fontStyle: fontStyle,
      fontWeight: fontWeight,
      fontSmallCaps: smallCaps,
      letterSpacing: letterSpacing,
      textDecoration: decoration,
      textDecorationColor: decorationColor,
      marginLeft: mLeft,
      marginTop: mTop,
      marginRight: mRight,
      marginBottom: mBottom,
      minWidth: minWidth,
      minHeight: minHeight,
      backgroundColor: bg,
      shadowOffsetX: shX,
      shadowOffsetY: shY,
      shadowBlur: shBlur,
      shadowColor: shColor,
      paddingLeft: pLeft,
      paddingTop: pTop,
      paddingRight: pRight,
      paddingBottom: pBottom,
      borderTopWidth: bwTop,
      borderRightWidth: bwRight,
      borderBottomWidth: bwBottom,
      borderLeftWidth: bwLeft,
      borderTopStyle: bsTop,
      borderRightStyle: bsRight,
      borderBottomStyle: bsBottom,
      borderLeftStyle: bsLeft,
      borderTopColor: bcTop,
      borderRightColor: bcRight,
      borderBottomColor: bcBottom,
      borderLeftColor: bcLeft,
      borderTopLeftRadius: rTL,
      borderTopRightRadius: rTR,
      borderBottomRightRadius: rBR,
      borderBottomLeftRadius: rBL,
      outlineColor: oc,
      outlineWidth: ow,
      outlineStyle: os,
    );
  }

  // ── Value parsing helpers ────────────────────────────────────────────────

  /// `top right bottom left` shorthand (CSS four-sides).
  ({T? top, T? right, T? bottom, T? left}) _four<T>(
    String raw,
    T? Function(String) parse,
  ) {
    final parts = raw.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty)
      return (top: null, right: null, bottom: null, left: null);
    T? at(int i) => i < parts.length ? parse(parts[i]) : null;
    if (parts.length == 1)
      return (top: at(0), right: at(0), bottom: at(0), left: at(0));
    if (parts.length == 2)
      return (top: at(0), right: at(1), bottom: at(0), left: at(1));
    if (parts.length == 3)
      return (top: at(0), right: at(1), bottom: at(2), left: at(1));
    return (top: at(0), right: at(1), bottom: at(2), left: at(3));
  }

  /// `border` / `border-top` shorthand → width/style/color.
  ({double? width, BorderStyle? style, Color? color}) _borderSide(String raw) {
    double? width;
    BorderStyle? style;
    Color? color;
    for (final part in raw.split(RegExp(r'\s+'))) {
      final w = _length(part);
      if (w != null && width == null) {
        width = w;
        continue;
      }
      final s = BorderStyle.parse(part);
      if (s != null && style == null) {
        style = s;
        continue;
      }
      final c = _parseCssColor(part);
      if (c != null && color == null) {
        color = c;
        continue;
      }
    }
    return (width: width, style: style, color: color);
  }

  /// `font: [style] [weight] size family` shorthand.
  ({TextStyle? style, int? weight, double? size, String? family})?
  _fontShorthand(String raw) {
    if (raw.trim().isEmpty || raw == 'inherit' || raw == 'initial') return null;
    TextStyle? style;
    int? weight;
    double? size;
    String? family;
    final tokens = raw
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .toList();
    var i = 0;
    // style
    if (tokens[i] == 'italic' || tokens[i] == 'oblique') {
      style = TextStyle.italic;
      i++;
    } else if (tokens[i] == 'normal') {
      i++;
    }
    // weight
    final w = _fontWeight(tokens[i]);
    if (w != null) {
      weight = w;
      i++;
    }
    // size
    size = _length(tokens[i]);
    if (size == null) return null;
    i++;
    // family — quoted or rest
    if (i < tokens.length) {
      final rest = tokens.sublist(i).join(' ');
      family = rest.replaceAll('"', '').replaceAll("'", '');
    }
    return (style: style, weight: weight, size: size, family: family);
  }

  ({TextDecoration? line, Color? color}) _textDecoration(String raw) {
    TextDecoration? line;
    Color? color;
    for (final part in raw.split(RegExp(r'\s+'))) {
      final l = _textDecorationLine(part);
      if (l != null) line = l;
      final c = _parseCssColor(part);
      if (c != null) color = c;
    }
    return (line: line, color: color);
  }

  TextDecoration? _textDecorationLine(String v) {
    switch (v.trim().toLowerCase()) {
      case 'underline':
        return TextDecoration.underline;
      case 'line-through':
        return TextDecoration.lineThrough;
      case 'none':
        return TextDecoration.none;
      default:
        return null;
    }
  }

  int? _fontWeight(String v) {
    switch (v.trim().toLowerCase()) {
      case 'normal':
        return 400;
      case 'bold':
        return 700;
      case 'bolder':
        return 800;
      case 'lighter':
        return 300;
      default:
        final n = int.tryParse(v);
        return n != null && n >= 100 && n <= 900 ? n : null;
    }
  }

  String? _fontFamily(String v) {
    final m = RegExp('["]([^"]*)["]').firstMatch(v);
    if (m != null && m.group(1)!.isNotEmpty) return m.group(1);
    final sq = RegExp("'[^']*'").firstMatch(v);
    if (sq != null && sq.group(0)!.length > 2)
      return sq.group(0)!.replaceAll("'", '');
    // Take the last bare token (e.g. "Sans", "Comic Sans MS" without quotes).
    final parts = v
        .split(',')
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return null;
    return parts.first.replaceAll('"', '').replaceAll("'", '');
  }

  ({double? x, double? y, double? blur, Color? color})? _boxShadow(String raw) {
    final v = raw.trim();
    if (v.isEmpty || v == 'none') return null;
    final lens = <double>[];
    Color? color;
    for (final tok in v.split(RegExp(r'\s+')).where((t) => t.isNotEmpty)) {
      final l = _length(tok);
      if (l != null) {
        if (lens.length < 3) lens.add(l);
      } else {
        final c = _parseCssColor(tok);
        if (c != null) color = c;
      }
    }
    return (
      x: lens.isNotEmpty ? lens[0] : null,
      y: lens.length > 1 ? lens[1] : null,
      blur: lens.length > 2 ? lens[2] : null,
      color: color ?? const Color(0, 0, 0, 128),
    );
  }

  double? _number(String raw) => double.tryParse(raw.trim());

  double? _length(String raw) {
    final v = raw.trim().toLowerCase();
    if (v.isEmpty || v == 'auto' || v == 'inherit' || v == 'initial')
      return null;
    final m = RegExp(r'^([-+]?[0-9]*\.?[0-9]+)\s*(px|pt)?$').firstMatch(v);
    if (m == null) return null;
    return double.tryParse(m.group(1)!);
  }

  Color? _parseCssColor(String? value) {
    if (value == null) return null;
    var v = value.trim().toLowerCase();
    if (v.isEmpty || v == 'transparent' || v == 'none')
      return const Color(0, 0, 0, 0);
    // symbolic color @name (from @define-color)
    if (v.startsWith('@')) {
      return _namedColors[v.substring(1)] ??
          _namedColors[v
              .substring(1)
              .replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '')];
    }
    if (v == 'currentcolor') return null; // resolved by caller context
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
    // rgb()/rgba() with numbers or percentages
    final rgba = RegExp(
      r'rgba?\s*\(\s*([0-9.]+%?)\s*,\s*([0-9.]+%?)\s*,\s*([0-9.]+%?)\s*(?:,\s*([0-9.]+%?))?\s*\)',
    ).firstMatch(v);
    if (rgba != null) {
      int comp(int gidx) {
        final s = rgba.group(gidx)!;
        if (s.endsWith('%')) {
          return ((double.parse(s.substring(0, s.length - 1)) / 100) * 255)
              .round();
        }
        return int.parse(s);
      }

      final r = comp(1).clamp(0, 255);
      final g = comp(2).clamp(0, 255);
      final b = comp(3).clamp(0, 255);
      var a = 255;
      if (rgba.group(4) != null) {
        final s = rgba.group(4)!;
        final af = s.endsWith('%')
            ? double.parse(s.substring(0, s.length - 1)) / 100
            : double.tryParse(s) ?? 1.0;
        a = (af <= 1 ? (af * 255).round() : af.round()).clamp(0, 255);
      }
      return Color(r, g, b, a);
    }
    // CSS color names (CSS3 SVG names — common subset).
    final named = _cssColorNames[v];
    if (named != null) return named;
    return null;
  }

  /// Common CSS color names (GTK uses the CSS3/SVG list; a representative
  /// subset is enough for real stylesheets).
  static final Map<String, Color> _cssColorNames = {
    'black': Color(0, 0, 0),
    'white': Color(255, 255, 255),
    'red': Color(255, 0, 0),
    'green': Color(0, 128, 0),
    'blue': Color(0, 0, 255),
    'yellow': Color(255, 255, 0),
    'gray': Color(128, 128, 128),
    'grey': Color(128, 128, 128),
    'silver': Color(192, 192, 192),
    'maroon': Color(128, 0, 0),
    'olive': Color(128, 128, 0),
    'lime': Color(0, 255, 0),
    'aqua': Color(0, 255, 255),
    'teal': Color(0, 128, 128),
    'navy': Color(0, 0, 128),
    'fuchsia': Color(255, 0, 255),
    'purple': Color(128, 0, 128),
    'orange': Color(255, 165, 0),
    'transparent': Color(0, 0, 0, 0),
  };
}

/// Matching helpers — handles:
/// `window#waybar`, `#pulseaudio`, `.module`, `button:hover`,
/// `#workspaces button`, `window#waybar.hidden`
bool _matchesSelector(String selector, List<Widget> chain) {
  final parts = selector
      .trim()
      .split(RegExp(r'\s+'))
      .where((s) => s.isNotEmpty)
      .toList();
  if (parts.isEmpty) return false;
  var chainIdx = chain.length - 1;
  var partIdx = parts.length - 1;
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
  final ids = RegExp(
    r'#([a-zA-Z0-9_-]+)',
  ).allMatches(part).map((m) => m.group(1)!).toList();
  final classes = RegExp(
    r'\.([a-zA-Z0-9_-]+)',
  ).allMatches(part).map((m) => m.group(1)!).toList();
  final pseudos = RegExp(
    r':([a-zA-Z0-9_-]+)',
  ).allMatches(part).map((m) => m.group(1)!).toList();
  final typeMatch = RegExp(r'^([a-zA-Z][a-zA-Z0-9_-]*)').firstMatch(part);
  final type = typeMatch?.group(1);

  if (type != null && type != '*' && type != 'window') {
    final wType = _widgetTypeName(w);
    if (wType != type && wType.toLowerCase() != type.toLowerCase())
      return false;
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

String _widgetTypeName(Widget w) => w.runtimeType.toString().toLowerCase();
