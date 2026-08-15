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
  final String fontFamily;

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
    this.fontFamily = 'sans',
  });

  /// Fold a nullable [StylePatch] on top: non-null values replace ours.
  Style overlay(StylePatch s) => Style(
    color: s.color ?? color,
    backgroundColor: s.backgroundColor ?? backgroundColor,
    borderColor: s.borderColor ?? borderColor,
    borderWidth: s.borderWidth ?? borderWidth,
    borderRadius: s.borderRadius ?? borderRadius,
    fontSize: s.fontSize ?? fontSize,
    fontFamily: s.fontFamily ?? fontFamily,
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
      'fs:$fontSize $fontFamily',
    ];
    return 'Style(${parts.join(' ')})';
  }
}
