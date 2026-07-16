# Phase 02: EGL Rendering Toolkit

This phase turns the Phase 1 prototype into a reusable EGL/GLES rendering toolkit that can power real apps. It adds robust surface handling, rendering helpers, and lifecycle integration with Wayland frame callbacks so future demos and apps can render reliably and resize correctly.

## Tasks

- [ ] Add EGL config selection utilities in `packages/gl/lib/src/egl/egl_config.dart` for RGBA, depth, stencil, and sRGB choices
- [ ] Extend `EglWindow` to handle resize events and recreate `wl_egl_window` + EGL surface when dimensions change
- [ ] Implement swap interval and buffer age configuration in `packages/gl/lib/src/egl/egl_context.dart` with sensible defaults
- [ ] Add a `Gles2Renderer` helper in `packages/gl/lib/src/gles2/renderer.dart` that compiles shaders, creates a simple pipeline, and draws a colored triangle
- [ ] Create `packages/window_toolkit/example/egl_triangle.dart` that uses `Gles2Renderer` and renders a triangle with a frame callback-driven loop
- [ ] Wire a frame callback API into `window_toolkit` so the render loop syncs with Wayland `wl_surface.frame` events
- [ ] Document the new rendering helpers and example commands in `packages/window_toolkit/README.md`
