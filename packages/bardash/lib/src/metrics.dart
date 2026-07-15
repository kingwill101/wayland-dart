/// Density / layout scale for the bar.
///
/// ## How spacing actually stacks
///
/// ```
/// | padL | content | padR |  spacing  | padL | content | padR |
/// |------ module A ------|  (bar)    |------ module B ------|
/// ```
///
/// - **content** — from each module's [BarModule.measure] (glyph bounds / icon
///   slot). This is the main source of accidental gaps when measure is loose.
/// - **padding** — inside the module hit box (waybar module padding). Default
///   is low; use for hover/chrome breathing room, not inter-module gap.
/// - **spacing** — single gap between top-level modules in the bar
///   [Container]. Prefer this for density between modules.
///
/// Adjacent modules therefore get `padR + spacing + padL` between content.
/// Keep pad small (0–2) and control density with [spacing] + tight measure.
///
/// Groups nest the same model: outer group pad + HBox of child ModuleWidgets
/// (child pad from `child-padding` / [groupChildPad]).
class BarMetrics {
  /// Named density used to pick this instance (`compact` / `normal` / …).
  final String name;

  /// Default bar height (pixels).
  final int barHeight;

  /// Gap between top-level modules ([Container.spacing]).
  final int spacing;

  /// Default horizontal padding per side when a module omits `padding`.
  final int modulePad;

  /// Default `child-padding` for modules inside a group.
  final int groupChildPad;

  /// Extra outer margin default (rarely needed).
  final int moduleMargin;

  /// Fixed width for icon-only custom modules (1–2 runes / FA glyphs).
  final int iconSlot;

  /// Gap between tray icons inside the SNI module.
  final int trayIconGap;

  /// Primary text size (labels, clock, CPU, …).
  final double fontSize;

  /// Slightly larger size for icon-font glyphs.
  final double iconFontSize;

  /// Horizontal breathing room added to tight text bounds (not full padding).
  final int contentFudge;

  /// Gap between an emoji/symbol and following text (volume, battery, …).
  final int iconTextGap;

  /// Family for color emoji (🔊 🔋 ⚡). Separate from FA/Nerd [icon] role.
  final String emojiFamily;

  const BarMetrics({
    required this.name,
    required this.barHeight,
    required this.spacing,
    required this.modulePad,
    required this.groupChildPad,
    required this.moduleMargin,
    required this.iconSlot,
    required this.trayIconGap,
    required this.fontSize,
    required this.iconFontSize,
    required this.contentFudge,
    this.iconTextGap = 4,
    this.emojiFamily = 'Noto Color Emoji',
  });

  /// Dense waybar-like bar (~28–30px). Prefer for ML4W-style layouts.
  ///
  /// Rhythm (after tight measure is fixed):
  /// - [spacing] = gap between top-level modules
  /// - [modulePad] = default pad inside each module (both sides)
  /// - [groupChildPad] = HBox gap between group children (icons)
  static const compact = BarMetrics(
    name: 'compact',
    barHeight: 30,
    // Between modules: padR + spacing + padL ≈ 1+4+1 = 6 with modulePad 1.
    spacing: 4,
    modulePad: 1,
    groupChildPad: 6,
    moduleMargin: 0,
    iconSlot: 16,
    trayIconGap: 4,
    fontSize: 13,
    iconFontSize: 14,
    contentFudge: 1,
    iconTextGap: 4,
  );

  /// Default balanced density.
  static const normal = BarMetrics(
    name: 'normal',
    barHeight: 30,
    spacing: 8,
    modulePad: 4,
    groupChildPad: 6,
    moduleMargin: 0,
    iconSlot: 18,
    trayIconGap: 6,
    fontSize: 13,
    iconFontSize: 14,
    contentFudge: 2,
    iconTextGap: 5,
  );

  /// Roomier bar for large displays / touch.
  static const comfortable = BarMetrics(
    name: 'comfortable',
    barHeight: 36,
    spacing: 10,
    modulePad: 6,
    groupChildPad: 8,
    moduleMargin: 0,
    iconSlot: 20,
    trayIconGap: 8,
    fontSize: 14,
    iconFontSize: 15,
    contentFudge: 2,
    iconTextGap: 6,
  );

  /// Active metrics for the running bar (set when config is applied).
  static BarMetrics current = normal;

  /// Parse `density = "compact"` style names; unknown → [normal].
  static BarMetrics fromName(String? name) {
    switch ((name ?? '').trim().toLowerCase()) {
      case 'compact':
      case 'dense':
      case 'tight':
        return compact;
      case 'comfortable':
      case 'roomy':
      case 'large':
        return comfortable;
      case 'normal':
      case 'default':
      case 'medium':
      case '':
        return normal;
      default:
        return normal;
    }
  }

  /// Measure short icon-like output (fixed slot so FA/emoji metrics don't bloat).
  bool isIconOutput(String text) {
    if (text.isEmpty) return false;
    return text.runes.length <= 2;
  }

  /// Width for icon-only content.
  double iconContentWidth() => iconSlot.toDouble();

  /// Tight text content width from glyph bounds + [contentFudge].
  double textContentWidth(
    double boundsWidth, {
    double min = 4,
    double max = 400,
  }) {
    return (boundsWidth + contentFudge).clamp(min, max);
  }

  /// Layout width for one emoji glyph: real advance, never under-measure.
  ///
  /// Using Hack/Nerd for emoji yields ~8px advance while the fallback paints
  /// ~16px — text then starts under the icon. Always measure with
  /// [emojiFamily] (Noto Color Emoji), not the FA/Nerd icon role.
  double emojiLayoutWidth(double measuredAdvance) {
    if (measuredAdvance < 4) return iconSlot.toDouble();
    // Prefer real advance; floor near iconSlot so we never under-clear ink.
    return measuredAdvance.clamp(iconSlot.toDouble() * 0.9, 24);
  }
}
