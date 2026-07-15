import 'drawing/color.dart';
import 'painter/painter.dart';
import 'palette.dart';

/// Qt-like abstract base for widget rendering.
/// Subclasses implement platform- or theme-specific drawing primitives.
abstract class Style {
  /// The palette used by this style.
  Palette get palette;

  /// Draw a push button face.
  void drawButton(Painter canvas, Rect rect, bool hovered, bool pressed, bool enabled);

  /// Draw a check box indicator.
  void drawCheckBox(Painter canvas, Rect rect, bool checked, bool hovered);

  /// Draw a radio button indicator.
  void drawRadioButton(Painter canvas, Rect rect, bool selected, bool hovered);

  /// Draw a slider groove (track).
  void drawSliderGroove(Painter canvas, Rect rect);

  /// Draw a slider handle (thumb).
  void drawSliderHandle(Painter canvas, double cx, double cy, double radius);

  /// Draw a text field frame.
  void drawTextFieldFrame(Painter canvas, Rect rect, bool focused);

  /// Draw a scrollbar groove.
  void drawScrollbarGroove(Painter canvas, Rect rect);

  /// Draw a scrollbar slider (thumb).
  void drawScrollbarSlider(Painter canvas, Rect rect, bool hovered);

  /// Draw a progress bar fill.
  void drawProgressBarFill(Painter canvas, Rect rect);

  /// Draw a progress bar background.
  void drawProgressBarBg(Painter canvas, Rect rect);

  /// Draw a menu item background.
  void drawMenuItem(Painter canvas, Rect rect, bool hovered, bool selected);

  /// Draw a focus ring around a widget.
  void drawFocusRect(Painter canvas, Rect rect);

  /// Draw a rounded panel / chip background.
  void drawPanel(Painter canvas, Rect rect, {bool elevated = false});

  /// The currently active style. Widgets read from here.
  static Style current = _defaultStyle;
}

final Style _defaultStyle = _FusionStyle();

class _FusionStyle extends Style {
  @override
  Palette get palette => Palette.current;

  @override
  void drawButton(Painter canvas, Rect rect, bool hovered, bool pressed, bool enabled) {
    final c = palette.forState(enabled, true);
    canvas.drawRect(rect, Paint()..color = pressed ? c.dark : hovered ? c.midlight : c.button);
  }

  @override
  void drawCheckBox(Painter canvas, Rect rect, bool checked, bool hovered) {
    final c = palette.forState(true, true);
    canvas.drawRect(rect, Paint()..color = c.base);
    canvas.drawRect(rect, Paint()..color = c.mid..style = PaintStyle.stroke);
    if (checked) {
      canvas.drawLine(Offset(rect.left + 3, rect.top + rect.height / 2),
          Offset(rect.left + rect.width / 2, rect.bottom - 3),
          Paint()..color = c.text..strokeWidth = 2);
      canvas.drawLine(Offset(rect.left + rect.width / 2, rect.bottom - 3),
          Offset(rect.right - 3, rect.top + 3),
          Paint()..color = c.text..strokeWidth = 2);
    }
  }

  @override
  void drawRadioButton(Painter canvas, Rect rect, bool selected, bool hovered) {
    final c = palette.forState(true, true);
    final cx = rect.center.dx;
    final cy = rect.center.dy;
    canvas.drawCircle(Offset(cx, cy), rect.width / 2, Paint()..color = c.base);
    canvas.drawCircle(Offset(cx, cy), rect.width / 2, Paint()..color = c.mid..style = PaintStyle.stroke);
    if (selected) {
      canvas.drawCircle(Offset(cx, cy), rect.width / 3, Paint()..color = c.text);
    }
  }

  @override
  void drawSliderGroove(Painter canvas, Rect rect) {
    final c = palette.forState(true, true);
    canvas.drawRect(rect, Paint()..color = c.mid);
  }

  @override
  void drawSliderHandle(Painter canvas, double cx, double cy, double radius) {
    final c = palette.forState(true, true);
    canvas.drawCircle(Offset(cx, cy), radius, Paint()..color = c.light);
  }

  @override
  void drawTextFieldFrame(Painter canvas, Rect rect, bool focused) {
    final c = palette.forState(true, true);
    canvas.drawRect(rect, Paint()..color = c.base);
    canvas.drawRect(Rect.fromLTWH(rect.left, rect.top, rect.width, 1),
        Paint()..color = focused ? c.highlight : c.mid);
    canvas.drawRect(Rect.fromLTWH(rect.left, rect.bottom - 1, rect.width, 1),
        Paint()..color = focused ? c.highlight : c.mid);
  }

  @override
  void drawScrollbarGroove(Painter canvas, Rect rect) {
    canvas.drawRect(rect, Paint()..color = const Color(35, 35, 35));
  }

  @override
  void drawScrollbarSlider(Painter canvas, Rect rect, bool hovered) {
    canvas.drawRect(rect, Paint()..color = hovered ? const Color(180, 180, 180) : const Color(140, 140, 140));
  }

  @override
  void drawProgressBarFill(Painter canvas, Rect rect) {
    canvas.drawRect(rect, Paint()..color = palette.forState(true, true).highlight);
  }

  @override
  void drawProgressBarBg(Painter canvas, Rect rect) {
    canvas.drawRect(rect, Paint()..color = palette.forState(true, true).mid);
  }

  @override
  void drawMenuItem(Painter canvas, Rect rect, bool hovered, bool selected) {
    canvas.drawRect(rect, Paint()..color = hovered ? const Color(55, 55, 55) : const Color(36, 36, 36));
  }

  @override
  void drawFocusRect(Painter canvas, Rect rect) {
    canvas.drawRect(rect, Paint()..color = palette.forState(true, true).highlight..style = PaintStyle.stroke);
  }

  @override
  void drawPanel(Painter canvas, Rect rect, {bool elevated = false}) {
    final c = palette.forState(true, true);
    final fill = elevated ? c.midlight : c.button;
    canvas.drawRRect(rect, 8, 8, Paint()..color = fill);
  }
}
