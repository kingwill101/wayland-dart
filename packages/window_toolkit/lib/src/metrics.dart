/// Shared layout/typography metrics for the toolkit.
///
/// Widgets and apps can read [ThemeMetrics.current] for consistent spacing
/// instead of hard-coding magic numbers.
class ThemeMetrics {
  final double fontSize;
  final double fontSizeSmall;
  final double fontSizeLarge;
  final int spacingXs;
  final int spacingSm;
  final int spacingMd;
  final int spacingLg;
  final int spacingXl;
  final int paddingSm;
  final int paddingMd;
  final int paddingLg;
  final double borderRadiusSm;
  final double borderRadiusMd;
  final double borderRadiusLg;
  final int iconSize;
  final int barHeight;

  const ThemeMetrics({
    this.fontSize = 13,
    this.fontSizeSmall = 11,
    this.fontSizeLarge = 16,
    this.spacingXs = 2,
    this.spacingSm = 4,
    this.spacingMd = 8,
    this.spacingLg = 12,
    this.spacingXl = 16,
    this.paddingSm = 4,
    this.paddingMd = 8,
    this.paddingLg = 12,
    this.borderRadiusSm = 4,
    this.borderRadiusMd = 8,
    this.borderRadiusLg = 12,
    this.iconSize = 16,
    this.barHeight = 30,
  });

  static ThemeMetrics current = const ThemeMetrics();

  static const compact = ThemeMetrics(
    fontSize: 12,
    spacingSm: 2,
    spacingMd: 4,
    paddingSm: 2,
    paddingMd: 4,
    barHeight: 28,
  );

  static const comfortable = ThemeMetrics(
    fontSize: 14,
    spacingSm: 6,
    spacingMd: 10,
    paddingSm: 6,
    paddingMd: 12,
    barHeight: 36,
  );
}
