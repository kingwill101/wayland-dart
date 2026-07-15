/// Horizontal / vertical text alignment — Qt [Qt::Alignment] inspired.
///
/// Combine with [TextLayout.layoutInRect] / [PainterFont.drawTextInRect] to
/// place baseline-relative text inside a box (bars, buttons, tooltips, menus).
enum TextHAlign {
  /// Qt::AlignLeft
  left,

  /// Qt::AlignHCenter
  center,

  /// Qt::AlignRight
  right,
}

/// Vertical alignment of a text line (or block) inside a rectangle.
enum TextVAlign {
  /// Top of ink / line box at rect top (Qt::AlignTop).
  top,

  /// Optical vertical center (Qt::AlignVCenter). Preferred for bar modules.
  center,

  /// Bottom of ink / line box at rect bottom (Qt::AlignBottom).
  bottom,

  /// Place the typographic baseline at the vertical center of the rect
  /// (useful when mixing icons with text).
  baselineCenter,
}

/// Alignment of text in a rectangle (Qt-style combined flags as a value type).
class TextAlign {
  final TextHAlign horizontal;
  final TextVAlign vertical;

  const TextAlign({
    this.horizontal = TextHAlign.left,
    this.vertical = TextVAlign.top,
  });

  /// Qt::AlignCenter
  static const center = TextAlign(
    horizontal: TextHAlign.center,
    vertical: TextVAlign.center,
  );

  /// Left + vertical center — typical for bar modules / list rows.
  static const leftCenter = TextAlign(
    horizontal: TextHAlign.left,
    vertical: TextVAlign.center,
  );

  /// Right + vertical center.
  static const rightCenter = TextAlign(
    horizontal: TextHAlign.right,
    vertical: TextVAlign.center,
  );

  /// Left + top (default document style).
  static const topLeft = TextAlign(
    horizontal: TextHAlign.left,
    vertical: TextVAlign.top,
  );

  /// Fully bottom-right.
  static const bottomRight = TextAlign(
    horizontal: TextHAlign.right,
    vertical: TextVAlign.bottom,
  );

  @override
  bool operator ==(Object other) =>
      other is TextAlign &&
      other.horizontal == horizontal &&
      other.vertical == vertical;

  @override
  int get hashCode => Object.hash(horizontal, vertical);

  @override
  String toString() => 'TextAlign($horizontal, $vertical)';
}

/// Elide mode — Qt [Qt::TextElideMode].
enum TextElideMode {
  /// No eliding.
  none,

  /// Elide at the end: `Hello wor…`
  right,

  /// Elide at the start: `…lo world`
  left,

  /// Elide in the middle: `Hel…rld`
  middle,
}
