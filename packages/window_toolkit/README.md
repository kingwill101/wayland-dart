# window_toolkit

A lightweight **Wayland client UI toolkit** for Dart. Build bars, panels, and
simple desktop windows without Flutter — pure Dart over Wayland protocols
(layer-shell, xdg-shell, subsurfaces).

## Install

```yaml
dependencies:
  window_toolkit: ^1.0.0
```

## Features

- **Layer shell bars** (`LayerWindow`) and **xdg toplevel windows**
- **Widget tree**: layout (Row/Column/Flex/HBox/VBox/Stack/Wrap), padding, align
- **Controls**: buttons, checkboxes, sliders, text fields, menus, tabs, dialogs, progress bars
- **Theming**: `Palette` + `Style` + `ThemeMetrics`
- **Tooltips** on layer surfaces via `TooltipOverlay` (subsurface)
- **GPU rendering** via GLES2 (`GlesPainter`) — SDF rounded rects, linear gradients, image loading, font-cached text
- **Skia** text shaping (HarfBuzz) + font fallback
- **Software fallback** via `RawPainter` when GPU unavailable

## Render Backend

Four backends via `RendererBackend` enum on `WindowBehavior`:

```dart
final bar = MyBar();
bar.rendererBackend = RendererBackend.gl;  // force GLES2
await bar.show();
```

| Backend | Description |
|---------|-------------|
| `auto`  | Try GLES2 first, then Skia, then software (default) |
| `gl`    | GPU-accelerated GLES2. Throws if unavailable. |
| `skia`  | Skia raster via SHM. Falls back to software. |
| `dawn`  | Skia Graphite via Dawn/WebGPU Vulkan. |

The toolkit-wide backend can be selected at launch without changing code:

```sh
WAYLAND_RENDERER_BACKEND=dawn my-wayland-app
```

Supported values are `auto`, `gl`, `skia`, and `dawn`. The existing
`BARDASH_BACKEND` variable is accepted as a compatibility alias. An explicit
`rendererBackend` assignment takes precedence over the environment.

## GLES2 Backend (GlesPainter)

The GL backend renders shapes using GPU shaders and reads pixels back via
`glReadPixels` (with automatic row flip for Wayland SHM). Text is rendered
by Skia into a temporary surface, uploaded as a GL texture, and drawn as a
textured quad with alpha multiplication.

Text textures are cached by content so repeated strings (clock, labels)
reuse the same GPU texture across frames.

- **`drawRect`** — filled or stroked (via `Paint.style` / `strokeWidth`)
- **`drawRRect`** — signed-distance field rounded rect (anti-aliased corners)
- **`drawCircle`** — filled or stroked (triangle fan / ring)
- **`drawLine`** — thickened line quad
- **`drawLinearGradient`** — two-colour gradient at any angle
- **`drawText`** — Skia-shaped text → GL texture → textured quad
- **`drawImage`** — Skia decode + scale → GL texture (tray icons, etc.)
- **`clipRect`** — scissor test with save/restore stack
- **`translate`** / **`scale`** — affine transform matrix stack

## Font Configuration

```dart
FontDatabase.instance.setRoleFamily(FontRole.ui, 'Noto Sans');
FontDatabase.instance.setRoleFamily(FontRole.icon, 'Hack Nerd Font');
FontDatabase.instance.setRoleFamily(FontRole.mono, 'JetBrains Mono');
```

Roles are resolved in `Font.ui()` / `Font.icon()` / `Font.mono()` helpers.

## Example

```dart
import 'package:window_toolkit/window_toolkit.dart';

void main() async {
  final bar = LayerWindow(anchor: Anchor.top, barHeight: 36);
  bar.rendererBackend = RendererBackend.gl;
  await bar.show();
  Application.instance.exec();
}
```

See `example/` for more complete examples.
