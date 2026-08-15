# Bardash module rendering inventory

The bar has one rendering boundary: `ModuleWidget`.  A module publishes
state (`output`, tooltip, and interaction callbacks); the toolkit owns widget
measurement, clipping, CSS, and painting wherever the module is text or a
standard control.

## Rendering classes

| Class | Modules | Rendering owner |
| --- | --- | --- |
| Text/status | `backlight`, `battery`, `bluetooth`, `clock`, `cpu`, `cpu-frequency`, `cpu-usage`, `disk`, `gamemode`, `gps`, `idle-inhibitor`, `inhibitor`, `keyboard-state`, `load`, `memory`, `mpd`, `network`, `power-profiles-daemon`, `privacy`, `systemd-failed`, `temperature`, `upower`, `user`, `volume`, `wireplumber`, `wwan`, `custom/*`, `separator`, and the `audio`/`mpris`/`pulseaudio` aliases | Toolkit `TextRuns` created by `ModuleWidget` |
| Toolkit composites | `group/*`, `hyprland/workspaces`, `hyprland/window`, `cpu/graph`, `custom/graph`, `pulseaudio-slider`, `backlight-slider` | Toolkit widget trees (`HBox`, `Button`, `Label`, `ProgressBar`, `Sparkline`) |
| Genuine graphics | `image` | Module-specific image/placeholder painter, clipped by `ModuleWidget` |
| Genuine graphics/surfaces | `sni`, `tray` | Status-notifier image decoding and tray menu surfaces; intentionally not text widgets |
| Legacy compatibility | `sway/workspaces`, `sway/window`, `sway/language`, `sway/mode`, `hyprland/language`, `hyprland/submap`, `hyprland/windowcount` | Text is routed through the toolkit text path; their old `draw` methods remain fallback compatibility until their state-specific controls are migrated |

`showsGraphics` is the explicit opt-out for modules that paint pixels beyond
their text.  A composite that already assigns `BarModule.widget` also bypasses
the text widget factory and remains responsible for syncing its child widgets.

## Shared rules

- Text and private-use icon glyphs are measured and painted by `TextRuns`.
- The active density's `BarMetrics.iconTextGap` is used for both measurement and
  drawing, so an icon cannot cover the first digit of a value such as `100%`.
- The module wrapper applies CSS background/border and clips its full allocated
  width, including toolkit children and genuine graphics.
- SNI/tray icons remain image-backed; replacing them with text glyphs would
  lose the app-provided icon and theme behavior.

## Migration status

The ordinary text family and the existing composite family now enter the
toolkit through `BarModule.widget`.  The remaining work is to remove dead
module-local `draw`/`measure` overrides in batches after each module's output
and geometry tests cover its formatting, and to replace the explicitly listed
legacy compatibility modules with stateful toolkit controls where their
interaction model requires one.
