# Wayland Window Toolkit — Batch 1: New Widgets + Infrastructure

## Context

`window_toolkit` is an early-stage Wayland UI toolkit (Dart). It has a small but consistent
widget set (`Button`, `Checkbox`, `RadioButton`, `Switch`, `Slider`, `ProgressBar`, `Card`,
`Frame`, `Separator`, `IconButton`, `Label`, `ImageIcon`, plus layout widgets
`Container`/`Align`/`Padding`/`Flex`/`HBox`/`VBox`/`Wrap`). Each widget follows a uniform
pattern (see `lib/src/widget.dart`):

- Base `Widget` = `x,y,width,height`, callbacks `onClick/onMouseEnter/onMouseLeave`,
  `measure(Painter)`, `draw(Painter)`, `hitTest(px,py)`.
- One file per widget under `lib/src/widgets/`, exported from `lib/window_toolkit.dart`.
- Tests use a `RecordingPainter` harness in `test/support/widget_test_harness.dart`.
- Examples are builder functions in `example/lib/*_examples.dart` with paired tests.

### Critical gaps discovered (why new infra is required)

1. **No shared display connection.** Every backend (`WaylandBackend`, `LayerBackend`) opens its
   own `Context().connect()` and binds globals itself. Real xdg-popups must be child surfaces of a
   toplevel that shares the same `WlDisplay`/`WlRegistry`/`XdgWmBase`. → Refactor to ONE shared
   connection owned by `Application`.
2. **No event routing to widgets.** Only `BarApp` hit-tests children (via `BarLayout`). The
   `Window`/`WidgetDemoWindow` demos never dispatch clicks to widgets. → Add a generic
   `WidgetWindow` + focus model.
3. **No repaint-on-change.** `paint()` runs only on `onConfigure`. → Add `requestRedraw()`.
4. **No clipping in `Painter`.** `SkiaPainter` can clip easily; `RawPainter` needs a scissor.
   → Add `clipRect(Rect)`.
5. **No wheel events.** Backend pointer handler emits enter/leave/motion/button but not axis.
   → Add `WlPointer.onAxis` → `MouseWheelEvent`.
6. **No character decoding.** `KeyEvent` carries a `Key` enum only. → libxkbcommon keymap
   (`WlKeyboard.onKeymap` FD) producing the typed `character`.

### Locked decisions (from user)

- Popups = **real Wayland xdg-popup surfaces** (not in-window overlays).
- Text input = **libxkbcommon keymap** (uses `WlKeyboard` keymap FD), not a static US map.
- Scope = **full set + all foundational infrastructure**.

## Goal

Add the foundational infrastructure AND the full widget set below, each with a `lib/src/widgets/`
implementation, a `window_toolkit.dart` export, an `example/lib/` builder, and a `test/widgets/`
unit test using the recording harness.

---

## Phase 0 — Shared display connection (backbone refactor)

This is the highest-risk change; do it first and keep `LayerBackend` behavior unchanged.

- Create `lib/src/backend/connection.dart`: `WaylandConnection` holds the single `Context`,
  `WlDisplay`, `WlRegistry`, and bound globals (`WlCompositor`, `WlShm`, `WlSeat`, `XdgWmBase`,
  `WlOutput`). Binds globals once in `connect()`; exposes getters for globals and a
  `dispatch()` that calls `context.dispatchTimeout(0)`.
- `Application` (`lib/src/app.dart`) creates and owns one `WaylandConnection`. `exec()` calls
  `connection.dispatch()` **once** per loop iteration (not per-backend). Backends no longer own a
  `Context`/registry.
- Refactor `WaylandBackend` and `LayerBackend` to take the shared `WaylandConnection` and use its
  globals. Keep their surface/buffer/present logic (reuse `createPainter`/`paintWithPainter`/
  `_present`). Ensure both still compile and the existing layer-bar + toplevel paths work.
- Keep `Backend` interface; add `connection` accessor. Update `Backend.dispatchEvents()` to be a
  no-op or delegate to the shared dispatch (avoid double-dispatch in `exec()`).

Validation: existing layer/example apps still run; no regression in `test/widgets/*` and
`test/examples/*`.

## Phase 1 — Input & rendering foundation

- **Wheel events**: in the shared seat setup, wire `WlPointer.onAxis` → new `MouseWheelEvent`
  (`dx`,`dy` from `RelativeAxis` + discrete/value120) dispatched via `Application`. Add
  `onMouseWheel` to `WindowBehavior` (`lib/src/window_behavior.dart`) mirroring other handlers.
- **libxkbcommon keymap**: new `lib/src/backend/keymap.dart` (FFI to libxkbcommon:
  `xkb_context_new`, `xkb_keymap_new_from_buffer`, `xkb_state_new`, `xkb_state_update_key`,
  `xkb_state_key_get_utf8`). On `WlKeyboard.onKeymap(format, fd, size)`, `mmap` the FD and build
  a `xkb_keymap`/`xkb_state`. On `WlKeyboard.onKey`, update state and compute the UTF-8 char.
  Add `String? character` (and keep `Key key`, `bool isPressed`, `ModifierState modifiers`) to
  `KeyEvent` (`lib/src/mixins/event.dart`). Fall back gracefully (no keymap loaded → `character`
  null) so tests/headless still work.
  - Dependency note: libxkbcommon must be available (system lib + FFI `DynamicLibrary.open`
    with a fallback to a bundled/static path). Call this out as a setup prerequisite.
- **Clipping**: add `void clipRect(Rect rect)` to `Painter` (`lib/src/painter/painter.dart`).
  Implement in `SkiaPainter` via `skCanvas.clipRect(...)` (pair with existing `save/restore`).
  Implement in `RawPainter` as a scissor rectangle that intersects primitive bounds in
  `drawRect/drawLine/drawCircle/drawText`. Add `clipRect` to `RecordingPainter` (record +
  transform the rect) and a `ClipRectCommand` so widget tests can assert clipping.

## Phase 2 — Widget runtime (event routing, focus, repaint)

- **`WidgetWindow`** (`lib/src/widgets/widget_window.dart`): a `Window` subclass holding a
  `Widget root`. On `onMouseMotion`/`onMouseButtonPressed`/`onMouseButtonReleased` it hit-tests
  the tree (deepest widget whose `hitTest` passes), tracks `hovered` to fire
  `onMouseEnter`/`onMouseLeave` transitions, and dispatches `onClick` and press/release to the
  target. This generalizes `BarApp`'s `BarLayout` hit-testing but for an arbitrary root.
- **Focus model**: `WidgetWindow` keeps `Widget? focusedWidget`. `requestFocus(w)`/`blur()` on
  `Widget`; clicks set focus (e.g., `TextField` focuses on press). `KeyEvent`s route to
  `focusedWidget` (and `character` reaches text widgets). `Esc`/click-outside blurs.
- **`requestRedraw()`**: expose `WindowBehavior.requestRedraw()` (calls `paint()`); widgets call
  it after state changes via their `onChanged`/interaction. Ensure it is safe to call during
  event dispatch (schedule a repaint flag, flush in next loop tick if needed).
- Wire `MouseWheelEvent` and `KeyEvent.character` through `WindowBehavior` → `WidgetWindow`.

## Phase 3 — Popup surface infrastructure

- **`PopupBackend`** (`lib/src/backend/popup.dart`): built from the shared `WaylandConnection`
  and a *parent* `XdgSurface`. Creates `WlSurface` + `XdgSurface.getPopup(parent, positioner)`
  using `XdgWmBase.createPositioner()` (set size/anchor/offset/grab serial). Owns its own
  buffer/`_present` (mirror `WaylandBackend` buffer logic). Handles `XdgPopup.onConfigure`
  (size) and `onPopupDone` (auto-close). Registered with `Application` as a backend so it shares
  dispatch/lifecycle.
- **`PopupWindow`** (`lib/src/widgets/popup_window.dart`): an `EventReceiver` + `WindowBehavior`
  wrapper around `PopupBackend` with the same `WidgetWindow` routing/focus/repaint machinery,
  so popup contents are built from the same `Widget` tree. Provide `show(anchorWidget)` that
  computes screen-relative position from the parent window + widget bounds and the grab serial
  from the opening pointer press.
- **`Overlay`/`MenuPopup` base** widget helper to standardize "toggle open/close" + outside-
  click dismissal (pointer leave / `popup_done`).

Validation: a Dropdown opening a real xdg-popup that captures clicks and dismisses on selection
or outside-click (manual smoke test; unit-test the positioner/serial plumbing with mocks).

## Phase 4 — Widgets (full set)

Each widget: `lib/src/widgets/<name>.dart`, export in `window_toolkit.dart`,
`example/lib/<name>_examples.dart` builder, `test/widgets/<name>_test.dart` via recording
harness. Reuse existing patterns (`Container`, `Card`, `Switch` hover/state, `Slider` drag math).

**Core interactive**
- `TextField` — `TextEditingController` (text, caret index, selection), editable via
  `KeyEvent.character` + Backspace/Delete/arrows/Home/End, horizontal scroll for overflow, focus
  ring, placeholder, password mask.
- `Dropdown` / `Select` — button + popup list (`PopupWindow`) of items; keyboard + click
  selection; current value label.
- `ListBox` — scrollable, multi/single select, wheel scroll, optional checkboxes; selection
  callbacks.
- `Tabs` / `TabBar` — tab header strip (clipped) + content area swapping; keyboard arrow nav.
- `ToggleButton` / `SegmentedControl` — mutually-exclusive (or multi) group of toggle buttons.

**Overlays & menus**
- `Menu` / `MenuItem` — popup menu built on `PopupWindow`; keyboard + hover nav; separators.
- `ContextMenu` — opens on right-click (`MouseButtonEvent` button != left) at cursor.
- `Dialog` — modal `PopupWindow` with title/body/action buttons; `xdg_dialog_v1` optional for
  modal hint; blocks underlying input while open.
- `Tooltip` — delayed hover popup (`PopupWindow`) near the hovered widget.

**Containers & visual**
- `ScrollArea` — scroll container with wheel + drag scroll and an optional `Scrollbar`.
- `GroupBox` / `FieldSet` — titled border container (clips/positions children).
- `Badge` / `Chip` / `Tag` — small adornment labels (count/status), optional close button.
- `Spinner` / `ActivityIndicator` — animated; uses an `EventLoop` periodic timer to
  `requestRedraw()` (add a lightweight timer registration so repaint fires without external
  triggers).
- `RangeSlider` — two-thumb min/max variant of `Slider`.

---

## File map (new / changed)

New:
- `lib/src/backend/connection.dart` (shared `WaylandConnection`)
- `lib/src/backend/keymap.dart` (libxkbcommon FFI)
- `lib/src/backend/popup.dart` (`PopupBackend`)
- `lib/src/widgets/widget_window.dart` (`WidgetWindow`, focus, routing, `requestRedraw`)
- `lib/src/widgets/popup_window.dart` (`PopupWindow`)
- `lib/src/widgets/{text_field,dropdown,list_box,tabs,toggle_button,menu,context_menu,dialog,tooltip,scroll_area,group_box,badge,spinner,range_slider}.dart`
- `lib/src/widgets/text_editing_controller.dart`
- `example/lib/*_examples.dart` (one per widget) + demo `WidgetWindow` app
- `test/widgets/*_test.dart` + infra tests (`keymap_test`, `clip_rect_test`, `routing_test`)

Changed:
- `lib/src/app.dart` (own shared connection; single dispatch in `exec`)
- `lib/src/backend/backend.dart`, `wayland.dart`, `layer.dart` (use shared connection)
- `lib/src/mixins/event.dart` (`MouseWheelEvent`, `KeyEvent.character`)
- `lib/src/window_behavior.dart` (`onMouseWheel`, `requestRedraw`)
- `lib/src/painter/painter.dart` (+ `RecordingPainter`) → `clipRect`
- `lib/src/painter/skia_painter.dart`, `raw_painter.dart` → `clipRect`
- `lib/window_toolkit.dart` → export all new public types

## Risks / open questions

- **Shared-connection refactor** touches the backbone; must preserve existing layer-bar and
  toplevel behavior (no regressions in current examples/tests).
- **libxkbcommon availability**: FFI needs the native lib present at runtime; provide a clear
  fallback (character stays null) and document the system dependency / how to bundle it.
- **xdg-popup grab serial**: popups must be opened with the serial of the triggering pointer
  button; the opening `MouseButtonEvent` must carry/expose that serial (extend event if needed).
- **Animation timer**: confirm `EventLoop.processOnce()` returns the next-delay so `Spinner`
  repaint is driven correctly without busy-looping.
- **`RawPainter` clipping** is approximate (scissor clamp, not perfect for text/AA); acceptable
  since Skia is the primary path.

## Validation

- `dart analyze` clean; `dart test` green (new widget tests + infra tests via recording harness;
  existing tests still pass).
- Manual smoke (real Wayland session): run the demo `WidgetWindow` app; verify each widget
  renders, interactive ones respond to click/hover/keyboard, `Dropdown`/`Menu`/`Dialog` open as
  real xdg-popups and dismiss correctly, wheel scrolls `ListBox`/`ScrollArea`, `TextField` types
  real characters via libxkbcommon.

## Rollout

Implement strictly in phase order (0 → 1 → 2 → 3 → 4). Each phase is independently
compilable/testable so the backbone can be validated before widgets depend on it.
