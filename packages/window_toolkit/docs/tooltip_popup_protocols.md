# Tooltip Popups from Layer Shell Surfaces

## The Problem

`BardashBar` (and `LayerWindow` in general) uses the `zwlr_layer_shell_v1` protocol
to create a panel/bar surface.  This surface has the **layer-surface role**, which
means its `wl_surface` already has a role assigned.  A `wl_surface` can have only
**one role** in its lifetime.

`xdg_popup` (the standard Wayland mechanism for tooltip/menu surfaces) requires a
**parent** `xdg_surface` that has been configured by the compositor.  Since the
bar's surface is a layer surface (not an xdg-toplevel), it cannot serve as the
parent — the protocol forbids it.

## Approaches Tried

### 1. In-bar drawing (fallback) — WORKS
Draw the tooltip text as part of the bar's SHM buffer at `y=0`.
- ✅ No protocol issues — purely visual
- ❌ Tooltip is inside the bar, not a separate surface
- ❌ Gets clipped if the tooltip text exceeds the bar's configured height
- **Verdict**: functional but not a real popup

### 2. Hidden xdg-toplevel as popup parent — CRASHES
Create a second `wl_surface`, wrap it as `xdg_surface` + `xdg_toplevel`,
keep it hidden (zero size / minimized), wait for configure, then use it
as the parent for `SurfaceManager`.
- ❌ Compositors reject zero-size or unmapped toplevels
- ❌ Hyprland sends "Invalid box" → disconnect → "Broken pipe"
- ❌ Race condition: the configure event might never arrive for an
    invisible toplevel
- **Verdict**: protocol violation, crashes the Wayland connection

### 3. `wl_subcompositor` + subsurface — PARTIAL
Create a second `wl_surface` and attach it as a child subsurface above the
bar surface via `wl_subcompositor.get_subsurface()`.
- ✅ Compositors support subsurfaces (core protocol, always available)
- ✅ Subsurface can extend beyond the parent's bounds
- ❌ Requires: binding `wl_subcompositor` global, SHM buffer management
    for the subsurface, and a render loop for the tooltip surface
- ❌ Subsurface doesn't get its own xdg-toplevel/popup — it's clipped to
    the output extents but can extend past the parent surface
- **Verdict**: doable but requires buffer management infrastructure

### 4. Tooltip as a second layer surface — HEAVY
Create a separate `zwlr_layer_surface_v1` positioned above the bar.
- ✅ Full surface with its own SHM buffer, no clipping
- ❌ `zwlr_layer_shell` surfaces are meant for panels/overlays, not tooltips
- ❌ Each tooltip show/hide requires creating & destroying a layer surface
    (expensive, visually jarring)
- **Verdict**: works but heavyweight

## Protocol Analysis

### `wl_subcompositor` (Wayland core, version 1)

The **subsurface** protocol lets you nest surfaces.  A child subsurface:
- Is positioned relative to its parent via `wl_subsurface.set_position(x, y)`
- Can extend beyond the parent's surface bounds
- Has its own SHM buffer and commit cycle
- Inherits the parent's buffer transform and scale

To implement tooltips via subsurface, `window_toolkit` needs:

```
WaylandConnection
  └── + bind wl_subcompositor global
       └── TooltipSurface
            ├── wl_surface (from compositor.createSurface)
            ├── wl_subsurface (from subcompositor.getSubsurface)
            ├── wl_shm_pool + wl_buffer (for the tooltip pixels)
            └── render() / hide() / destroy()
```

### `xdg_wm_base` (XDG shell stable)

The **xdg-popup** path is the "proper" Wayland approach, but it requires
a configured parent xdg_surface.  Options to make it work:

#### Option A: Composite surface (dual-role workaround)
On some compositors you can create a **wrapper** wl_surface that acts purely
as the popup parent without being mapped.  This is non-portable.

#### Option B: Zero-size xdg-toplevel with `set_minimized()`
The `xdg_toplevel.set_minimized()` request hints the compositor that the
window should not be shown.  Some compositors honour this and still send
configure events; others (Hyprland) reject it.

#### Option C: `xdg_surface` without a toplevel role
Create an `xdg_surface` from a fresh `wl_surface` but DO NOT call
`get_toplevel()` or `get_popup()`.  Commit the surface.  The compositor
sends an `xdg_surface.configure` event with `width=0, height=0`.
This configured (but roleless) xdg_surface can serve as a popup parent
on some compositors, but it's not guaranteed by the spec.

### `ext-layer-shell` / `ext-popup` (staging protocols)

The [ext-layer-shell](https://gitlab.freedesktop.org/wayland/wayland-protocols/-/tree/main/staging/ext-layer-shell)
protocol adds popup support for layer surfaces.  This is the **correct**
future solution but is still in staging and not widely deployed.

## Recommended Implementation

### Phase 1 — Subsurface tooltips (immediate)

Add `wl_subcompositor` binding to `WaylandConnection` and implement
`TooltipOverlay` as a subsurface-based tooltip surface.

**`window_toolkit/lib/src/tooltip_overlay.dart`**:

```dart
class TooltipOverlay {
  /// Creates a subsurface tooltip.  [parentSurface] is the bar's wl_surface.
  TooltipOverlay({
    required WaylandConnection connection,
    required WlSurface parentSurface,
  });

  /// Show the tooltip at (x, y) in parent-surface coordinates.
  /// The subsurface extends above the parent when y is negative.
  void show(String text, {int x = 0, int y = -24});

  /// Hide the tooltip (move off-screen).
  void hide();

  /// Release native resources.
  void destroy();
}
```

The implementation:
1. Bind `wl_subcompositor` in `WaylandConnection._onGlobal`
2. Create a helper `_ensureBuffer(w, h)` that creates a wl_surface +
   wl_subsurface + shm_pool + wl_buffer with the same pattern as
   `LayerBackend._ensurePool()`
3. On `show()`: position subsurface via `setPosition()` and render text
   onto the subsurface's SHM buffer via `SkiaPainter`
4. On `hide()`: move subsurface off-screen via `setPosition(0, -9999)`

### Phase 2 — `LayerWindow` integration

Add a `tooltip` property to `LayerWindow` (and thus `BardashBar`) that
manages a `TooltipOverlay` instance automatically:

```dart
mixin LayerTooltip on LayerWindow {
  TooltipOverlay? _tooltip;
  String _lastTooltip = '';

  /// Call from onMouseMotion / onMouseLeave.
  void _updateTooltip(String text, int mouseX) {
    if (text == _lastTooltip) return;
    _lastTooltip = text;
    if (text.isEmpty) { _tooltip?.hide(); return; }
    _tooltip ??= TooltipOverlay(
      connection: connection,
      parentSurface: surface,
    );
    _tooltip!.show(text, x: mouseX - text.length * 3, y: -24);
  }
}
```

### Phase 3 — Proper protocol detection

For compositors that support xdg-popup with an unmapped xdg_surface parent
(like KWin, River), fall back to `SurfaceManager` + hidden parent.
Detect support by attempting the setup and catching the error.

## Summary

| Approach | Status | Protocol | Portability |
|----------|--------|----------|-------------|
| In-bar drawing | ✅ Works | None | Universal |
| Subsurface | 🔧 Needs implementation | `wl_subcompositor` | Universal |
| Hidden xdg-toplevel | ❌ Crashes | `xdg_wm_base` | Hyprland fails |
| Second layer surface | ❌ Heavyweight | `zwlr_layer_shell` | Universal |
| ext-layer-shell popup | ⏳ Staging | `ext-layer-shell` | Future |
