/// Font description — Qt [QFont]-inspired value type.
///
/// Describes *what* font you want. Resolution to a concrete face is done by
/// [FontDatabase] / a [FontEngine] backend (Skia, bitmap, …).
class Font {
  /// Preferred family name (e.g. `"Noto Sans"`, `"Hack Nerd Font"`, `"sans"`).
  final String family;

  /// Pixel size (device pixels). Qt also has pointSize; we standardize on px
  /// for bar/UI toolkits where DPI is often 1:1 logical.
  final double pixelSize;

  /// Weight 100–900 (Qt5+: Thin=100 … Black=900). [FontWeight.normal] = 400.
  final int weight;

  final bool italic;

  /// Hint when [family] is empty or cannot be matched.
  final FontStyleHint styleHint;

  /// Optional role for app theming (`ui`, `icon`, `mono`) — resolved via
  /// [FontDatabase.setRoleFamily] when set.
  final FontRole? role;

  const Font({
    this.family = '',
    this.pixelSize = 13,
    this.weight = FontWeight.normal,
    this.italic = false,
    this.styleHint = FontStyleHint.sansSerif,
    this.role,
  });

  /// UI body text defaults.
  const Font.ui({double pixelSize = 13, int weight = FontWeight.normal})
      : this(role: FontRole.ui, pixelSize: pixelSize, weight: weight);

  /// Icon / symbol font (Font Awesome, Nerd Font, emoji).
  const Font.icon({double pixelSize = 14})
      : this(role: FontRole.icon, pixelSize: pixelSize);

  /// Monospace (tooltips, code).
  const Font.mono({double pixelSize = 12})
      : this(role: FontRole.mono, pixelSize: pixelSize);

  Font copyWith({
    String? family,
    double? pixelSize,
    int? weight,
    bool? italic,
    FontStyleHint? styleHint,
    FontRole? role,
  }) {
    return Font(
      family: family ?? this.family,
      pixelSize: pixelSize ?? this.pixelSize,
      weight: weight ?? this.weight,
      italic: italic ?? this.italic,
      styleHint: styleHint ?? this.styleHint,
      role: role ?? this.role,
    );
  }

  bool get bold => weight >= FontWeight.bold;

  @override
  bool operator ==(Object other) =>
      other is Font &&
      other.family == family &&
      other.pixelSize == pixelSize &&
      other.weight == weight &&
      other.italic == italic &&
      other.styleHint == styleHint &&
      other.role == role;

  @override
  int get hashCode =>
      Object.hash(family, pixelSize, weight, italic, styleHint, role);

  @override
  String toString() =>
      'Font($family ${pixelSize}px w=$weight${italic ? ' italic' : ''}'
      '${role != null ? ' role=$role' : ''})';
}

/// Qt-style weight constants (QFont::Weight).
abstract final class FontWeight {
  static const int thin = 100;
  static const int extraLight = 200;
  static const int light = 300;
  static const int normal = 400;
  static const int medium = 500;
  static const int demiBold = 600;
  static const int bold = 700;
  static const int extraBold = 800;
  static const int black = 900;
}

/// Qt [QFont::StyleHint] analogue — used when matching fails.
enum FontStyleHint {
  /// Any sans-serif (default UI).
  sansSerif,

  /// Serif body text.
  serif,

  /// Fixed pitch.
  typewriter,

  /// Fantasy / decorative.
  fantasy,

  /// Cursive.
  cursive,

  /// System default.
  system,

  /// No preference.
  any,
}

/// Named font roles for applications (beyond raw family strings).
enum FontRole {
  /// Primary UI / labels.
  ui,

  /// Icons, emoji, PUA symbols.
  icon,

  /// Monospace (tooltips, debug).
  mono,
}
