# Phase 04: Advanced EGL Features

This phase expands GPU support with modern Wayland-friendly paths such as dmabuf import/export, optional explicit sync, and improved performance tooling. These features unlock richer rendering pipelines and set the stage for integrating external renderers later.

## Tasks

- [ ] Add EGL extensions loader utilities in `packages/gl/lib/src/egl/egl_extensions.dart` to query and cache extension strings
- [ ] Implement dmabuf import helpers using `linux-dmabuf` protocol bindings and EGL image creation
- [ ] Add optional explicit sync wiring via `linux-explicit-synchronization` when available
- [ ] Create a `packages/window_toolkit/example/egl_dmabuf.dart` demo that imports a dmabuf-backed buffer and presents it
- [ ] Add performance logging hooks (frame time, swap time) in the EGL render loop utilities
