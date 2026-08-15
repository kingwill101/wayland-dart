/// General widget style resolution.
///
/// A `StyleContext` answers "what style applies to a widget given its style
/// ancestry" by merging every registered [StyleProvider] by priority — the
/// highest-priority provider wins a property it sets, lower providers fill the
/// gaps. This is the toolkit's **general** style system.
///
/// CSS is a single addon: `CssProvider` implements [StyleProvider] and is
/// registered with [addProvider]. Palettes/theme defaults live on the widgets
/// themselves and are consulted only when a property is unset.
library;

import '../drawing/color.dart';
import '../widget.dart';
import '../style.dart';
import 'style_provider.dart';
import 'style_patch.dart';

class _ProviderEntry {
  final StyleProvider provider;
  _ProviderEntry(this.provider);
}

class _ProviderStyleCache {
  int epoch = -1;
  List<Widget> chain = const [];
  List<int> revisions = const [];
  StylePatch? value;

  bool matches(int currentEpoch, List<Widget> currentChain) {
    if (value == null ||
        epoch != currentEpoch ||
        chain.length != currentChain.length) {
      return false;
    }
    for (var i = 0; i < chain.length; i++) {
      if (!identical(chain[i], currentChain[i]) ||
          revisions[i] != currentChain[i].styleRevision) {
        return false;
      }
    }
    return true;
  }

  void store(int currentEpoch, List<Widget> currentChain, StylePatch result) {
    epoch = currentEpoch;
    chain = List<Widget>.of(currentChain);
    revisions = [for (final item in currentChain) item.styleRevision];
    value = result;
  }
}

class StyleContext {
  static final List<_ProviderEntry> _providers = [];
  static final Expando<_ProviderStyleCache> _cache =
      Expando<_ProviderStyleCache>();
  static int _providerEpoch = 0;

  /// Register a [StyleProvider]; higher [priority] wins conflicting props.
  static void addProvider(StyleProvider provider, {int? priority}) {
    if (priority != null) provider.priority = priority;
    _providers.add(_ProviderEntry(provider));
    // Stable priority ordering — higher priority wins (checked later).
    _providers.sort(
      (a, b) => a.provider.priority.compareTo(b.provider.priority),
    );
    _providerEpoch++;
  }

  /// Mirrors `Gtk::StyleContext::add_provider_for_screen(screen, provider, priority)`.
  /// Registers a `CssProvider` (the CSS addon) at [priority].
  static void addProviderForScreen(StyleProvider provider, {int priority = 1}) {
    provider.priority = priority;
    _providers.add(_ProviderEntry(provider));
    _providers.sort(
      (a, b) => a.provider.priority.compareTo(b.provider.priority),
    );
    _providerEpoch++;
  }

  static void removeProvider(StyleProvider provider) {
    _providers.removeWhere((e) => identical(e.provider, provider));
    _providerEpoch++;
  }

  static void removeProviderForScreen(StyleProvider provider) =>
      removeProvider(provider);

  /// For testing — clears all providers.
  static void reset() {
    _providers.clear();
    _providerEpoch++;
  }

  static List<StyleProvider> get providers =>
      List.unmodifiable(_providers.map((e) => e.provider));

  final Widget widget;
  final List<Widget> chain; // root ... widget

  StyleContext._(this.widget, this.chain);

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
    while (cur != null) {
      chain.insert(0, cur);
      cur = cur.parent;
    }
    if (chain.isEmpty) chain.add(w);
    return chain;
  }

  /// The merged, typed style from every provider (highest priority wins).
  StylePatch get style {
    return _providerStyle(widget, chain);
  }

  static StylePatch _providerStyle(Widget widget, List<Widget> chain) {
    final cached = _cache[widget] ??= _ProviderStyleCache();
    if (cached.matches(_providerEpoch, chain)) return cached.value!;

    var resolved = StylePatch.empty;
    // Providers sorted low->high; higher applied later so it overrides.
    for (final entry in _providers) {
      resolved = resolved.apply(entry.provider.styleFor(widget, chain));
    }
    cached.store(_providerEpoch, chain, resolved);
    return resolved;
  }

  // ── Typed convenience accessors ──────────────────────────────────────────

  Color? get parsedColor => style.color;
  Color? get parsedBackgroundColor => style.backgroundColor;
  Color? get parsedBorderColor => style.borderColor;
  double? get borderRadius => style.borderRadius;
  double? get borderWidth => style.borderWidth;
  double? get fontSizeValue => style.fontSize;
  int? get paddingLeft => style.paddingLeft;
  int? get paddingTop => style.paddingTop;
  int? get paddingRight => style.paddingRight;
  int? get paddingBottom => style.paddingBottom;

  /// **The** single cascade point for the concrete style a widget draws.
  ///
  /// This is the one place the whole resolution happens — nothing CSS-specific
  /// lives in widgets. The pipeline is:
  ///
  ///   role (inherited palette defaults) → registered providers (CSS is just
  ///   one addon) → widget [[local]] explicit override.
  ///
  /// [role] is the widget's inherited global-palette defaults; [local] the
  /// widget's own explicit values. `pseudos` (e.g. `['hover']`) resolve an
  /// active state for the lookup only.
  static Style resolveStyle(
    Widget widget, {
    required Style role,
    List<String> pseudos = const [],
    StylePatch local = StylePatch.empty,
  }) {
    final prev = <String, bool>{};
    List<String>? applied;
    if (pseudos.isNotEmpty) {
      applied = [];
      for (final p in pseudos) {
        prev[p] = widget.hasPseudoClass(p);
        widget.addPseudoClass(p);
        applied.add(p);
      }
    }

    final providerChain = _chainFromParents(widget);
    // Temporary pseudo-state is intentionally not cached: the revision while
    // it is applied is transient and would otherwise poison the normal state.
    final merged = pseudos.isEmpty
        ? _providerStyle(widget, providerChain)
        : _mergeProviders(widget, providerChain);

    if (applied != null) {
      for (final p in applied) {
        widget.removePseudoClass(p);
        if (prev[p]!) widget.addPseudoClass(p);
      }
    }

    // role → widget-local override → providers (CSS) last (highest).
    final concrete = role.overlay(local).overlay(merged);

    // GTK/Pango-style inherited properties. A module often owns a composite
    // widget tree (label + graph/slider), while its CSS selector is attached
    // to the module wrapper. Let descendants inherit text-facing properties
    // without leaking the parent's surface/background into every child.
    final parent = widget.parent;
    if (parent == null) return concrete;
    final parentStyle = resolveStyle(
      parent,
      role: parent.styleRole(),
      local: parent.localOverrides(),
    );
    return concrete.overlay(
      StylePatch(
        color: local.color == null && merged.color == null
            ? parentStyle.color
            : null,
        fontFamily: local.fontFamily == null && merged.fontFamily == null
            ? parentStyle.fontFamily
            : null,
        fontSize: local.fontSize == null && merged.fontSize == null
            ? parentStyle.fontSize
            : null,
        letterSpacing:
            local.letterSpacing == null && merged.letterSpacing == null
            ? parentStyle.letterSpacing
            : null,
        opacity: local.opacity == null && merged.opacity == null
            ? parentStyle.opacity
            : null,
      ),
    );
  }

  static StylePatch _mergeProviders(Widget widget, List<Widget> chain) {
    var merged = StylePatch.empty;
    for (final entry in _providers) {
      merged = merged.apply(entry.provider.styleFor(widget, chain));
    }
    return merged;
  }

  // GTK-style helpers used by waybar modules.
  bool hasClass(String cls) => widget.hasClass(cls);
}
