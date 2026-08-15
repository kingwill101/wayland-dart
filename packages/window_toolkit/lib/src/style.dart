import 'drawing/color.dart';
import 'style/style_patch.dart';

/// The fully **resolved**, concrete style a widget actually renders with.
///
/// Unlike [StylePatch] (all-nullable = "unset"), a [Style] has the
/// cascade already folded in, in a single place (`StyleContext.resolveStyle`):
///
///   1. role defaults (the widget's inherited global-palette colors),
///   2. registered style providers — CSS being just one addon,
///   3. the widget's own explicit override.
///
/// so drawings read only concrete values like `style.color` /
/// `style.backgroundColor`. No widget re-implements the cascade.
class Style {
  final Color color; // foreground
  final Color borderColor;
  final double borderWidth;
  final double borderRadius;
  final double fontSize;
  final double letterSpacing;
  final String fontFamily;
  final double opacity;
  final double? shadowOffsetX;
  final double? shadowOffsetY;
  final double? shadowBlur;
  final Color? shadowColor;

  /// Background is `null` = "draw no background" (a legitimate effective
  /// value; everything else is concrete).
  final Color? backgroundColor;

  const Style({
    required this.color,
    required this.borderColor,
    this.backgroundColor,
    this.borderWidth = 1,
    this.borderRadius = 12,
    this.fontSize = 14,
    this.letterSpacing = 0,
    this.fontFamily = 'sans',
    this.opacity = 1,
    this.shadowOffsetX,
    this.shadowOffsetY,
    this.shadowBlur,
    this.shadowColor,
  });

  /// Fold a nullable [StylePatch] on top: non-null values replace ours.
  Style overlay(StylePatch s) => Style(
    color: s.color ?? color,
    backgroundColor: s.backgroundColor ?? backgroundColor,
    borderColor: s.borderColor ?? borderColor,
    borderWidth: s.borderWidth ?? borderWidth,
    borderRadius: s.borderRadius ?? borderRadius,
    fontSize: s.fontSize ?? fontSize,
    letterSpacing: s.letterSpacing ?? letterSpacing,
    fontFamily: s.fontFamily ?? fontFamily,
    opacity: s.opacity ?? opacity,
    shadowOffsetX: s.shadowOffsetX ?? shadowOffsetX,
    shadowOffsetY: s.shadowOffsetY ?? shadowOffsetY,
    shadowBlur: s.shadowBlur ?? shadowBlur,
    shadowColor: s.shadowColor ?? shadowColor,
  );

  /// Fold several [StylePatch]s on top in order.
  Style overlayAll(List<StylePatch> list) {
    var r = this;
    for (final s in list) {
      r = r.overlay(s);
    }
    return r;
  }

  @override
  String toString() {
    final parts = <String>[
      'fg:$color',
      if (backgroundColor != null) 'bg:$backgroundColor',
      'border:$borderColor w$borderWidth r$borderRadius',
      'fs:$fontSize $fontFamily ls$letterSpacing op$opacity',
      if (shadowColor != null) 'shadow:$shadowColor',
    ];
    return 'Style(${parts.join(' ')})';
  }
}
