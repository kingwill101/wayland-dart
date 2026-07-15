import 'font.dart';

/// Resolved font info — Qt [QFontInfo]-inspired.
///
/// After matching, this is what the backend actually selected (family may
/// differ from the request if fallbacks ran).
class FontInfo {
  final String family;
  final double pixelSize;
  final int weight;
  final bool italic;
  final bool fixedPitch;
  final bool exactMatch;

  const FontInfo({
    required this.family,
    required this.pixelSize,
    this.weight = FontWeight.normal,
    this.italic = false,
    this.fixedPitch = false,
    this.exactMatch = true,
  });

  bool get bold => weight >= FontWeight.bold;

  @override
  String toString() =>
      'FontInfo($family ${pixelSize}px w=$weight'
      '${fixedPitch ? ' fixed' : ''}${exactMatch ? '' : ' ~fallback'})';
}
