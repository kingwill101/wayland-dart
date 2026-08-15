import '../drawing/color.dart';

/// Border rendering style (CSS `border-*-style`).
enum BorderStyle {
  none,
  solid,
  dotted,
  dashed,
  groove,
  ridge,
  inset,
  outset,
  hidden;

  static BorderStyle? parse(String? s) {
    switch (s?.trim().toLowerCase()) {
      case 'none':
        return none;
      case 'solid':
        return solid;
      case 'dotted':
        return dotted;
      case 'dashed':
        return dashed;
      case 'hidden':
        return hidden;
      default:
        return null;
    }
  }
}

/// Font style (CSS `font-style`).
enum TextStyle { normal, italic, oblique }

/// Underline / strikethrough decorations (CSS `text-decoration-line`).
enum TextDecoration { none, underline, lineThrough }

/// A nullable style contribution from a theme, CSS provider, or widget-local
/// override. The toolkit folds patches into a concrete [Style] before draw.
///
/// This is the **general** style model — widgets consume *typed* values
/// (colors, fonts, padding, radii) and fall back to theme/palette defaults
/// when a property is unset. Sources (the theme/palette defaults, programmatic
/// presets, CSS providers) each contribute a [StylePatch]; `StyleContext`
/// merges them by priority so the most specific source wins.
///
/// CSS is just one addon that injects into this model — see `CssProvider`,
/// which maps its declarations onto these typed properties. The model covers
/// roughly the same surface as GTK's CSS properties (see
/// `doc/style-system.md` for the catalog).
class StylePatch {
  // ── Color ───────────────────────────────────────────────────────────────
  final Color? color; // foreground (text/icon) — GTK `color`
  final double? opacity; // GTK `opacity`

  // ── Font ────────────────────────────────────────────────────────────────
  final String? fontFamily; // GTK `font-family`
  final double? fontSize; // GTK `font-size`
  final TextStyle? fontStyle; // GTK `font-style`
  final int? fontWeight; // GTK `font-weight` 100..900
  final bool? fontSmallCaps; // GTK `font-variant: small-caps`
  final double? letterSpacing; // GTK `letter-spacing`
  final TextDecoration? textDecoration; // GTK `text-decoration-line`
  final Color? textDecorationColor; // GTK `text-decoration-color`

  // ── Box ─────────────────────────────────────────────────────────────────
  final int? marginLeft; // GTK `margin-left`
  final int? marginTop; // GTK `margin-top`
  final int? marginRight; // GTK `margin-right`
  final int? marginBottom; // GTK `margin-bottom`
  final double? minWidth; // GTK `min-width`
  final double? minHeight; // GTK `min-height`

  // ── Background ──────────────────────────────────────────────────────────
  final Color? backgroundColor; // GTK `background-color`
  // Simplified `box-shadow` — a single soft drop shadow.
  final double? shadowOffsetX;
  final double? shadowOffsetY;
  final double? shadowBlur;
  final Color? shadowColor;

  // ── Padding (GTK `padding-*`) ───────────────────────────────────────────
  final int? paddingLeft;
  final int? paddingTop;
  final int? paddingRight;
  final int? paddingBottom;

  // ── Border (GTK `border-*-width|style|color`, `border-*-radius`) ────────
  final double? borderTopWidth;
  final double? borderRightWidth;
  final double? borderBottomWidth;
  final double? borderLeftWidth;
  final BorderStyle? borderTopStyle;
  final BorderStyle? borderRightStyle;
  final BorderStyle? borderBottomStyle;
  final BorderStyle? borderLeftStyle;
  final Color? borderTopColor;
  final Color? borderRightColor;
  final Color? borderBottomColor;
  final Color? borderLeftColor;
  final double? borderTopLeftRadius;
  final double? borderTopRightRadius;
  final double? borderBottomRightRadius;
  final double? borderBottomLeftRadius;

  // ── Outline (focus rectangle) ───────────────────────────────────────────
  final Color? outlineColor; // GTK `outline-color`
  final double? outlineWidth; // GTK `outline-width`
  final BorderStyle? outlineStyle; // GTK `outline-style`

  const StylePatch({
    this.color,
    this.opacity,
    this.fontFamily,
    this.fontSize,
    this.fontStyle,
    this.fontWeight,
    this.fontSmallCaps,
    this.letterSpacing,
    this.textDecoration,
    this.textDecorationColor,
    this.marginLeft,
    this.marginTop,
    this.marginRight,
    this.marginBottom,
    this.minWidth,
    this.minHeight,
    this.backgroundColor,
    this.shadowOffsetX,
    this.shadowOffsetY,
    this.shadowBlur,
    this.shadowColor,
    this.paddingLeft,
    this.paddingTop,
    this.paddingRight,
    this.paddingBottom,
    this.borderTopWidth,
    this.borderRightWidth,
    this.borderBottomWidth,
    this.borderLeftWidth,
    this.borderTopStyle,
    this.borderRightStyle,
    this.borderBottomStyle,
    this.borderLeftStyle,
    this.borderTopColor,
    this.borderRightColor,
    this.borderBottomColor,
    this.borderLeftColor,
    this.borderTopLeftRadius,
    this.borderTopRightRadius,
    this.borderBottomRightRadius,
    this.borderBottomLeftRadius,
    this.outlineColor,
    this.outlineWidth,
    this.outlineStyle,
  });

  /// Convenience: uniform border color (top-left is authoritative fallback).
  Color? get borderColor => borderTopColor ?? borderLeftColor;

  /// Convenience: uniform border width (top-left is authoritative fallback).
  double? get borderWidth => borderTopWidth ?? borderLeftWidth;

  /// Convenience: uniform border radius (top-left is authoritative fallback).
  double? get borderRadius => borderTopLeftRadius ?? borderTopRightRadius;

  int? get paddingHorizontal {
    final l = paddingLeft, r = paddingRight;
    if (l != null && r != null) return l >= r ? l : r;
    return l ?? r;
  }

  int? get paddingVertical {
    final t = paddingTop, b = paddingBottom;
    if (t != null && b != null) return t >= b ? t : b;
    return t ?? b;
  }

  /// A style with every property unset.
  static const StylePatch empty = StylePatch();

  bool get isEmpty =>
      color == null &&
      opacity == null &&
      fontFamily == null &&
      fontSize == null &&
      fontStyle == null &&
      fontWeight == null &&
      fontSmallCaps == null &&
      letterSpacing == null &&
      textDecoration == null &&
      textDecorationColor == null &&
      marginLeft == null &&
      marginTop == null &&
      marginRight == null &&
      marginBottom == null &&
      minWidth == null &&
      minHeight == null &&
      backgroundColor == null &&
      shadowBlur == null &&
      shadowColor == null &&
      paddingLeft == null &&
      paddingTop == null &&
      paddingRight == null &&
      paddingBottom == null &&
      borderTopWidth == null &&
      borderRightWidth == null &&
      borderBottomWidth == null &&
      borderLeftWidth == null &&
      borderTopStyle == null &&
      borderRightStyle == null &&
      borderBottomStyle == null &&
      borderLeftStyle == null &&
      borderTopColor == null &&
      borderRightColor == null &&
      borderBottomColor == null &&
      borderLeftColor == null &&
      borderTopLeftRadius == null &&
      borderTopRightRadius == null &&
      borderBottomRightRadius == null &&
      borderBottomLeftRadius == null &&
      outlineColor == null &&
      outlineWidth == null &&
      outlineStyle == null;

  /// Merge [other] on top: every non-null property in [other] wins.
  StylePatch apply(StylePatch other) => StylePatch(
    color: other.color ?? color,
    opacity: other.opacity ?? opacity,
    fontFamily: other.fontFamily ?? fontFamily,
    fontSize: other.fontSize ?? fontSize,
    fontStyle: other.fontStyle ?? fontStyle,
    fontWeight: other.fontWeight ?? fontWeight,
    fontSmallCaps: other.fontSmallCaps ?? fontSmallCaps,
    letterSpacing: other.letterSpacing ?? letterSpacing,
    textDecoration: other.textDecoration ?? textDecoration,
    textDecorationColor: other.textDecorationColor ?? textDecorationColor,
    marginLeft: other.marginLeft ?? marginLeft,
    marginTop: other.marginTop ?? marginTop,
    marginRight: other.marginRight ?? marginRight,
    marginBottom: other.marginBottom ?? marginBottom,
    minWidth: other.minWidth ?? minWidth,
    minHeight: other.minHeight ?? minHeight,
    backgroundColor: other.backgroundColor ?? backgroundColor,
    shadowOffsetX: other.shadowOffsetX ?? shadowOffsetX,
    shadowOffsetY: other.shadowOffsetY ?? shadowOffsetY,
    shadowBlur: other.shadowBlur ?? shadowBlur,
    shadowColor: other.shadowColor ?? shadowColor,
    paddingLeft: other.paddingLeft ?? paddingLeft,
    paddingTop: other.paddingTop ?? paddingTop,
    paddingRight: other.paddingRight ?? paddingRight,
    paddingBottom: other.paddingBottom ?? paddingBottom,
    borderTopWidth: other.borderTopWidth ?? borderTopWidth,
    borderRightWidth: other.borderRightWidth ?? borderRightWidth,
    borderBottomWidth: other.borderBottomWidth ?? borderBottomWidth,
    borderLeftWidth: other.borderLeftWidth ?? borderLeftWidth,
    borderTopStyle: other.borderTopStyle ?? borderTopStyle,
    borderRightStyle: other.borderRightStyle ?? borderRightStyle,
    borderBottomStyle: other.borderBottomStyle ?? borderBottomStyle,
    borderLeftStyle: other.borderLeftStyle ?? borderLeftStyle,
    borderTopColor: other.borderTopColor ?? borderTopColor,
    borderRightColor: other.borderRightColor ?? borderRightColor,
    borderBottomColor: other.borderBottomColor ?? borderBottomColor,
    borderLeftColor: other.borderLeftColor ?? borderLeftColor,
    borderTopLeftRadius: other.borderTopLeftRadius ?? borderTopLeftRadius,
    borderTopRightRadius: other.borderTopRightRadius ?? borderTopRightRadius,
    borderBottomRightRadius:
        other.borderBottomRightRadius ?? borderBottomRightRadius,
    borderBottomLeftRadius:
        other.borderBottomLeftRadius ?? borderBottomLeftRadius,
    outlineColor: other.outlineColor ?? outlineColor,
    outlineWidth: other.outlineWidth ?? outlineWidth,
    outlineStyle: other.outlineStyle ?? outlineStyle,
  );

  /// Fill this style's unset properties from [seed] (seed is lower priority).
  StylePatch fillFrom(StylePatch seed) => StylePatch(
    color: color ?? seed.color,
    opacity: opacity ?? seed.opacity,
    fontFamily: fontFamily ?? seed.fontFamily,
    fontSize: fontSize ?? seed.fontSize,
    fontStyle: fontStyle ?? seed.fontStyle,
    fontWeight: fontWeight ?? seed.fontWeight,
    fontSmallCaps: fontSmallCaps ?? seed.fontSmallCaps,
    letterSpacing: letterSpacing ?? seed.letterSpacing,
    textDecoration: textDecoration ?? seed.textDecoration,
    textDecorationColor: textDecorationColor ?? seed.textDecorationColor,
    marginLeft: marginLeft ?? seed.marginLeft,
    marginTop: marginTop ?? seed.marginTop,
    marginRight: marginRight ?? seed.marginRight,
    marginBottom: marginBottom ?? seed.marginBottom,
    minWidth: minWidth ?? seed.minWidth,
    minHeight: minHeight ?? seed.minHeight,
    backgroundColor: backgroundColor ?? seed.backgroundColor,
    shadowOffsetX: shadowOffsetX ?? seed.shadowOffsetX,
    shadowOffsetY: shadowOffsetY ?? seed.shadowOffsetY,
    shadowBlur: shadowBlur ?? seed.shadowBlur,
    shadowColor: shadowColor ?? seed.shadowColor,
    paddingLeft: paddingLeft ?? seed.paddingLeft,
    paddingTop: paddingTop ?? seed.paddingTop,
    paddingRight: paddingRight ?? seed.paddingRight,
    paddingBottom: paddingBottom ?? seed.paddingBottom,
    borderTopWidth: borderTopWidth ?? seed.borderTopWidth,
    borderRightWidth: borderRightWidth ?? seed.borderRightWidth,
    borderBottomWidth: borderBottomWidth ?? seed.borderBottomWidth,
    borderLeftWidth: borderLeftWidth ?? seed.borderLeftWidth,
    borderTopStyle: borderTopStyle ?? seed.borderTopStyle,
    borderRightStyle: borderRightStyle ?? seed.borderRightStyle,
    borderBottomStyle: borderBottomStyle ?? seed.borderBottomStyle,
    borderLeftStyle: borderLeftStyle ?? seed.borderLeftStyle,
    borderTopColor: borderTopColor ?? seed.borderTopColor,
    borderRightColor: borderRightColor ?? seed.borderRightColor,
    borderBottomColor: borderBottomColor ?? seed.borderBottomColor,
    borderLeftColor: borderLeftColor ?? seed.borderLeftColor,
    borderTopLeftRadius: borderTopLeftRadius ?? seed.borderTopLeftRadius,
    borderTopRightRadius: borderTopRightRadius ?? seed.borderTopRightRadius,
    borderBottomRightRadius:
        borderBottomRightRadius ?? seed.borderBottomRightRadius,
    borderBottomLeftRadius:
        borderBottomLeftRadius ?? seed.borderBottomLeftRadius,
    outlineColor: outlineColor ?? seed.outlineColor,
    outlineWidth: outlineWidth ?? seed.outlineWidth,
    outlineStyle: outlineStyle ?? seed.outlineStyle,
  );

  @override
  String toString() {
    final parts = <String>[
      if (color != null) 'color:$color',
      if (backgroundColor != null) 'bg:$backgroundColor',
      if (opacity != null) 'op:$opacity',
      if (fontFamily != null) 'family:$fontFamily',
      if (fontSize != null) 'fs:$fontSize',
      if (borderWidth != null) 'bw:${borderWidth}',
      if (borderRadius != null) 'r:${borderRadius}',
      if (paddingLeft != null || paddingTop != null)
        'pad:[$paddingLeft,$paddingTop,$paddingRight,$paddingBottom]',
    ];
    return 'StylePatch(${parts.join(' ')})';
  }
}
