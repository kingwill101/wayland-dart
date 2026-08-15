# Bardash module rendering inventory

The bar has one rendering boundary: `ModuleWidget`.  A module publishes
state (`output`, tooltip, and interaction callbacks); the toolkit owns widget
measurement, clipping, CSS, and painting wherever the module is text or a
standard control.

## Rendering classes

| Class | Modules | Rendering owner |
| --- | --- | --- |
| Text/status | `backlight`, `battery`, `bluetooth`, `clock`, `cpu`, `cpu-frequency`, `cpu-usage`, `disk`, `gamemode`, `gps`, `idle-inhibitor`, `inhibitor`, `keyboard-state`, `load`, `memory`, `mpd`, `network`, `power-profiles-daemon`, `privacy`, `systemd-failed`, `temperature`, `upower`, `user`, `volume`, `wireplumber`, `wwan`, `custom/*`, `separator`, and the `audio`/`mpris`/`pulseaudio` aliases | Toolkit `TextRuns` created by `ModuleWidget` |
| Toolkit composites | `group/*`, `hyprland/workspaces`, `hyprland/window`, `cpu/graph`, `custom/graph`, `pulseaudio-slider`, `backlight-slider` | Toolkit widget trees (`HBox`, `Button`, `Label`, `ProgressBar`, `Sparkline`); module painters are not involved |
| Genuine graphics | `image` | Module-specific image/placeholder painter, clipped by `ModuleWidget` |
| Genuine graphics/surfaces | `sni`, `tray` | Status-notifier image decoding and tray menu surfaces; intentionally not text widgets |
| Legacy compatibility | `sway/workspaces`, `sway/window`, `sway/language`, `sway/mode`, `hyprland/language`, `hyprland/submap`, `hyprland/windowcount` | Text is routed through the same toolkit `TextRuns` path; these names remain compatibility modules because their compositor-specific state sources are separate |

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

The ordinary text family no longer owns module-local text measurement or
painting. The remaining painter overrides are limited to real pixels: image
and SNI/tray surfaces. Composite graphs, sliders, groups, workspaces, and
window labels are measured and painted by their toolkit child trees. The registry test
asserts that every non-graphics module receives a toolkit `TextRuns` child;
future modules should satisfy that invariant instead of adding a custom text
renderer.
