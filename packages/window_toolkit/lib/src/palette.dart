import 'drawing/color.dart';

/// Qt-like color groups for a widget's state.
class ColorGroup {
  final Color window;
  final Color windowText;
  final Color base;
  final Color text;
  final Color button;
  final Color buttonText;
  final Color highlight;
  final Color highlightedText;
  final Color disabledText;
  final Color placeholderText;
  final Color light;
  final Color midlight;
  final Color mid;
  final Color dark;
  final Color shadow;
  final Color brightText;
  final Color link;
  final Color tooltipBase;
  final Color tooltipText;
  final Color success;
  final Color danger;

  const ColorGroup({
    this.window = const Color(22, 22, 22),
    this.windowText = const Color(255, 255, 255),
    this.base = const Color(30, 30, 30),
    this.text = const Color(255, 255, 255),
    this.button = const Color(50, 50, 50),
    this.buttonText = const Color(255, 255, 255),
    this.highlight = const Color(60, 100, 200),
    this.highlightedText = const Color(255, 255, 255),
    this.disabledText = const Color(100, 100, 100),
    this.placeholderText = const Color(100, 100, 100),
    this.light = const Color(70, 70, 70),
    this.midlight = const Color(55, 55, 55),
    this.mid = const Color(45, 45, 45),
    this.dark = const Color(30, 30, 30),
    this.shadow = const Color(15, 15, 15),
    this.brightText = const Color(255, 255, 255),
    this.link = const Color(80, 160, 255),
    this.tooltipBase = const Color(40, 40, 40),
    this.tooltipText = const Color(255, 255, 255),
    this.success = const Color(70, 160, 90),
    this.danger = const Color(200, 60, 60),
  });

  static const darkGroup = ColorGroup();
  static const lightGroup = ColorGroup(
    window: Color(240, 240, 240),
    windowText: Color(30, 30, 30),
    base: Color(255, 255, 255),
    text: Color(30, 30, 30),
    button: Color(220, 220, 220),
    buttonText: Color(30, 30, 30),
    highlight: Color(60, 100, 200),
    highlightedText: Color(255, 255, 255),
    disabledText: Color(160, 160, 160),
    placeholderText: Color(160, 160, 160),
    light: Color(240, 240, 240),
    midlight: Color(220, 220, 220),
    mid: Color(180, 180, 180),
    dark: Color(120, 120, 120),
    shadow: Color(60, 60, 60),
    brightText: Color(255, 255, 255),
    link: Color(0, 100, 200),
    tooltipBase: Color(240, 240, 240),
    tooltipText: Color(30, 30, 30),
  );
}

/// Qt-like QPalette with active/inactive/disabled color groups.
class Palette {
  final ColorGroup active;
  final ColorGroup inactive;
  final ColorGroup disabled;

  const Palette({
    this.active = const ColorGroup(),
    this.inactive = const ColorGroup(),
    this.disabled = const ColorGroup(),
  });

  ColorGroup forState(bool enabled, bool activeWindow) {
    if (!enabled) return disabled;
    if (!activeWindow) return inactive;
    return active;
  }

  /// The active palette. Widgets read from here.
  static Palette current = Palette.darkPalette;

  static const darkPalette = Palette();
  static const lightPalette = Palette(
    active: ColorGroup.lightGroup,
    inactive: ColorGroup.lightGroup,
    disabled: ColorGroup.lightGroup,
  );
}
