# Audio popup + Lua UI — status

Two directions; both have a working first slice (shipped code in `lib/src/`).

---

## 1. A click-to-open audio panel (Windows-tray style)  — IMPLEMENTED

Goal: clicking an audio module pops a compact panel with a draggable master
volume slider + mute toggle, instead of a bare number.

### Shipped
- `lib/src/audio_popup.dart`:
  - `AudioPanelLayout` — pure geometry + hit-testing (unit-tested headless).
  - `AudioPopupController.open/close/isOpen` — static host API, like the tray.
  - `AudioPopupOverlay` — a dedicated `zwlr_layer_shell` overlay surface, a
    transparent full-output **dismiss catcher** (click outside closes), SHM
    double-buffering, pointer routing, Escape/click close.
  - **Output + Mic rows**: dragging either slider calls
    `PulseClient.stepVolume` / `stepSourceVolume`; the Mute pills call
    `toggleMute` / `toggleSourceMute` (source controls added to the C shim:
    `pulse_shim_source_volume_step`, `pulse_shim_toggle_source_mute`, rebuilt
    `libpulse_shim.so`, bindings regenerated via ffigen).
  - **Mixer button**: opens an external mixer — configurable via
    `mixer-command` on the module, else auto-detects pavucontrol /
    pwvucontrol / helvum / qpwgraph.
  - A live `PulseListener` repaints on sink+source changes.
- `lib/src/modules/audio.dart`: `AudioModule` (`"audio"` in a bar config) —
  draws `{icon} {volume}%` + a small level bar (density-aware, `BarText` PUA
  glyphs, `cssForeground`-tinted). Left-click opens/closes the panel; it
  attaches to the live `WaylandConnection` via `AudioModule.attach(...)`,
  wired from `bar.dart` exactly like the SNI tray. Falls back to
  `pactl`/`amixer` poll + a mute toggle when the native shim / layer-shell is
  absent.
- Tests: `test/audio_popup_test.dart` (layout geometry, clamps, hit-zones,
  registry) — **7 tests**.

### Layout reuse
This path deliberately does **not** refactor `tray_menu.dart` (a delicate SNI
surface). It copies the *proven* overlay discipline (layer surface + dismiss
catcher + SHM double-buffer + pointer routing). A **shared popup base** is
still worth doing later if a third popup appears; until then the two stay
decoupled so an SNI integration risk can't break the audio panel.

---

## 2. Drawing UI entirely from Lua — PROTOTYPE (record/replay protocol)

bardash embeds a Lua VM in-process (`package:lualike`). The bridge is a
**record + replay** protocol:

```
Lua (cv_rect/rrect/text/circle/slider) → LuaUi.commands (UiRect/UiText/…)
replay → any window_toolkit Painter (Skia live / RecordingPainter in tests)
```

- `lib/src/lua_ui.dart` registers the `cv_*` globals into Lua via `vm.expose`;
  Lua never touches Dart objects. `LuaUi.paint(painter)` replays.
- `test/lua_ui_test.dart` runs a Lua "volume panel" script and replays it
  through `RecordingPainter` (panel rect, slider thumb circle, labels).
- **Not a widget DSL** and **not in `window_toolkit`** by design: Lua authors
  draw primitives; `lua_ui.dart` lives in bardash and only depends on the
  toolkit's `Painter`/`Rect`/`Color`.

---

## Open / next
- Shared `PopupOverlay` base (only if/when a 3rd popup appears).
- Per-app mixer rows in the audio panel (read sink-inputs via the pulse shim).
- Optional declarative Lua node DSL (`{type, …}`) on top of the `cv_*` set.