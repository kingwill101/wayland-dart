/// Shared bar text measure/draw helpers (UI vs icon/emoji fonts).
library;

import 'package:window_toolkit/window_toolkit.dart';

import 'metrics.dart';

/// Helpers so modules pick the right font for Nerd/FA glyphs vs UI text.
class BarText {
  BarText._();

  /// UI labels (clock, percentages without private-use icons).
  static Font uiFont([double? pixelSize]) =>
      Font.ui(pixelSize: pixelSize ?? BarMetrics.current.fontSize);

  /// Icon role (Nerd Font / FA) — family from [FontDatabase] role map.
  static Font iconFont([double? pixelSize]) =>
      Font.icon(pixelSize: pixelSize ?? BarMetrics.current.iconFontSize);

  /// Color emoji family from [BarMetrics.emojiFamily].
  static Font emojiFont([double? pixelSize]) => Font(
    family: BarMetrics.current.emojiFamily,
    pixelSize: pixelSize ?? BarMetrics.current.fontSize,
  );

  /// True if [text] contains Private Use Area codepoints (Nerd/FA icons).
  static bool hasIconGlyphs(String text) {
    return FontTextRun.isPrivateUse(text);
  }

  /// Font for a single-string module output (icon glyphs → icon role).
  static Font fontFor(String text) {
    if (text.isEmpty) return uiFont();
    if (hasIconGlyphs(text) || BarMetrics.current.isIconOutput(text)) {
      return iconFont();
    }
    return uiFont();
  }

  /// Measure bar content width (handles empty, icon slot, fudge).
  static double measure(Painter painter, String text) {
    if (text.isEmpty) return 0;
    final m = BarMetrics.current;
    if (m.isIconOutput(text) && !hasIconGlyphs(text)) {
      // Short non-PUA (rare) — still use icon slot when marked icon-like.
      return m.iconContentWidth();
    }
    var adv = painter.measureTextRuns(
      text,
      textFont: uiFont(),
      iconFont: iconFont(),
      runSpacing: m.iconTextGap.toDouble(),
      splitPrivateUse: true,
    );
    // After cache purge / bad match, PUA can measure as ~0 — fall back to slot.
    if (hasIconGlyphs(text) && adv < 4) {
      adv = m.iconContentWidth();
    }
    // Icon-only PUA: prefer fixed slot so metrics noise doesn't widen modules.
    if (m.isIconOutput(text) && hasIconGlyphs(text)) {
      final slot = m.iconContentWidth();
      // Use real advance when larger (some FA glyphs are wider than iconSlot).
      return adv < slot ? slot : adv.clamp(slot, 32);
    }
    return m.textContentWidth(adv);
  }

  /// Draw [text] and return its advance width.
  static double draw(
    Painter painter,
    String text,
    double x,
    double y, {
    Color? color,
    Font? font,
  }) {
    if (text.isEmpty) return 0;
    late final double measured;
    if (font == null) {
      measured = painter.drawTextRuns(
        text,
        Offset(x, y),
        textFont: uiFont(),
        iconFont: iconFont(),
        color: color,
        runSpacing: BarMetrics.current.iconTextGap.toDouble(),
        splitPrivateUse: true,
      );
    } else {
      painter.drawTextFont(text, Offset(x, y), font: font, color: color);
      measured = painter.measureTextFont(text, font);
    }
    if (hasIconGlyphs(text) && measured < 4) {
      return BarMetrics.current.iconContentWidth();
    }
    return measured;
  }

  /// Pick the first family available on the system from [candidates].
  ///
  /// Matching order (per candidate):
  /// 1. Exact case-insensitive family name
  /// 2. Installed name contains the full candidate (e.g. "Hack Nerd Font Mono")
  /// 3. Never match a *shorter* installed name that is only a prefix of the
  ///    candidate — that used to pick bare `Hack` over `Hack Nerd Font`, which
  ///    has no PUA icons (empty quicklinks / power glyph).
  ///
  /// Falls back to [fallback] when none match (Skia may still resolve it).
  static String resolveFamily(
    List<String> candidates, {
    String fallback = 'sans',
  }) {
    List<String> installed;
    try {
      installed = FontDatabase.instance.families();
    } catch (_) {
      return candidates.isNotEmpty ? candidates.first : fallback;
    }
    if (installed.isEmpty) {
      return candidates.isNotEmpty ? candidates.first : fallback;
    }
    final lower = installed.map((f) => f.toLowerCase()).toList();

    for (final c in candidates) {
      final cl = c.toLowerCase().trim();
      if (cl.isEmpty) continue;

      // 1) Exact
      for (var i = 0; i < lower.length; i++) {
        if (lower[i] == cl) return installed[i];
      }

      // 2) Installed contains candidate as a full token-ish substring,
      //    preferring the *longest* installed match (Nerd Mono > Nerd).
      String? best;
      var bestLen = -1;
      for (var i = 0; i < lower.length; i++) {
        final il = lower[i];
        if (il.contains(cl) && il.length > bestLen) {
          best = installed[i];
          bestLen = il.length;
        }
      }
      if (best != null) return best;

      // 3) Candidate contains installed only when installed is long enough
      //    to be meaningful (≥ candidate length − small slack). Blocks
      //    matching "Hack" for candidate "Hack Nerd Font".
      best = null;
      bestLen = -1;
      for (var i = 0; i < lower.length; i++) {
        final il = lower[i];
        if (il.length < 4) continue;
        if (cl.contains(il) &&
            il.length >= (cl.length - 2) &&
            il.length > bestLen) {
          best = installed[i];
          bestLen = il.length;
        }
      }
      if (best != null) return best;
    }
    return candidates.isNotEmpty ? candidates.first : fallback;
  }

  /// Default Nerd/FA icon family search list (first match wins).
  static const iconFamilyCandidates = <String>[
    'Hack Nerd Font',
    'Hack Nerd Font Mono',
    'FiraCode Nerd Font',
    'FiraCode Nerd Font Mono',
    'Symbols Nerd Font',
    'Symbols Nerd Font Mono',
    'JetBrainsMono Nerd Font',
    'Font Awesome 7 Free',
    'Font Awesome 6 Free',
    'Font Awesome 5 Free',
    'Noto Sans Symbols 2',
    'Noto Sans Symbols',
  ];
}
