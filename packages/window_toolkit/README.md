# window_toolkit

A lightweight **Wayland client UI toolkit** for Dart. Build bars, panels, and
simple desktop windows without Flutter — pure Dart over Wayland protocols
(layer-shell, xdg-shell, subsurfaces) with Skia text/raster.

## Features

- **Layer shell bars** (`LayerWindow`) and **xdg toplevel windows**
- **Widget tree**: layout (Row/Column/Flex/HBox/VBox/Stack/Wrap), padding, align
- **Controls**: buttons, checkboxes, sliders, text fields, menus, tabs, dialogs
- **Theming**: `Palette` + `Style` + `ThemeMetrics`
- **Tooltips** on layer surfaces via `TooltipOverlay` (subsurface)
- **Skia** text shaping (HarfBuzz) + rounded rects

## Getting started

```yaml
dependencies:
  window_toolkit:
    path: packages/window_toolkit
```

```dart
import 'package:window_toolkit/window_toolkit.dart';

Future<void> main() async {
  final win = WidgetWindow(
    title: 'Demo',
    width: 400,
    height: 300,
  );
  // ... set root widget, show, exec
  await win.show();
  Application.instance.exec();
}
```

For a panel:

```dart
class MyBar extends LayerWindow {
  MyBar() : super(anchor: Anchor.top, barHeight: 30, exclusiveZone: 30);

  @override
  void draw(Painter painter) {
    painter.clear(Palette.current.active.window);
    // draw modules...
  }
}
```

## Layout building blocks

| Widget | Role |
|--------|------|
| `Row` / `Column` / `Flex` | Flexbox-like main/cross axis |
| `HBox` / `VBox` | Simple horizontal / vertical stacks |
| `Padding` / `Align` / `Center` | Spacing and alignment |
| `SizedBox` / `ConstrainedBox` | Fixed / clamped size |
| `Stack` / `Positioned` | Overlay children |
| `DecoratedBox` | Background, border, rounded corners |
| `Chip` | Pill button (workspaces, tags) |
| `Label` | Measured text + ellipsis + baseline center |
| `MouseRegion` | Hover / tap without changing layout |
| `Separator` | Visual divider |

## Theming

```dart
Palette.current = Palette.darkPalette;
// or
Palette.current = Palette.lightPalette;

ThemeMetrics.current = ThemeMetrics.compact;
```

Colors live in `ColorGroup` (`tooltipBase`, `highlight`, `button`, …).
Drawing chrome goes through `Style.current` (buttons, scrollbars, panels).

## Fonts & text positioning (Qt-style)

`FontDatabase` plus **rect-aligned text** — a small port of Qt’s font and
`QPainter::drawText` stack with **pluggable engines**:

| Qt | window_toolkit |
|----|----------------|
| `QFont` | `Font` |
| `QFontDatabase` | `FontDatabase` |
| `QFontMetricsF` | `FontMetrics` |
| `QFontInfo` | `FontInfo` |
| platform DB | `FontEngine` → `SkiaFontEngine` / `BitmapFontEngine` |
| `Qt::Alignment` | `TextAlign` / `TextHAlign` / `TextVAlign` |
| `QTextOption` | `TextOption` |
| `QPainter::drawText(QRect, flags, text)` | `painter.drawTextInRect(...)` / `TextLayout` |

```dart
// Production (Skia + system Fontconfig via SkFontMgr)
FontDatabase.instance.useSkiaEngine();
FontDatabase.instance.setRoleFamily(FontRole.ui, 'Noto Sans');
FontDatabase.instance.setRoleFamily(FontRole.icon, 'Hack Nerd Font');

final m = FontDatabase.instance.metrics(Font.ui(pixelSize: 13));
final width = m.horizontalAdvance('Apps'); // layout width (not loose ink bounds)

// Align text in a rectangle (baseline computed for vertical center)
painter.drawTextInRect(
  'Apps',
  Rect.fromLTWH(0, 0, 80, 30),
  font: Font.ui(),
  option: TextOption.leftCenter, // left + v-center
);

// Tests / raw painter
FontDatabase.instance.useBitmapEngine();
```

**Baseline vs top:** low-level `drawText` is baseline-relative (Skia/QPainter).
Always use `drawTextInRect` / `TextLayout.baselineInBox` for UI so glyphs sit
optically mid-bar / mid-button — not stuck to the top of the box.

Use **`horizontalAdvance`** for layout width. Prefer roles (`Font.ui` /
`Font.icon` / `Font.mono`) over hard-coded family strings in apps.

## Tooltips on layer surfaces

`xdg_popup` cannot parent from a layer-shell surface. Use `TooltipOverlay`
(subsurface) instead — see `docs/tooltip_popup_protocols.md`.

## Tests

```bash
cd packages/window_toolkit && dart test
```

## Package layout

```
lib/src/
  backend/     # Wayland connection, layer, popup
  painter/     # Skia / raw painters
  widgets/     # UI components
  metrics.dart # ThemeMetrics
  palette.dart # Color roles
  style.dart   # Drawing chrome
```
