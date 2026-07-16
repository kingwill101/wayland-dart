# Phase 01: EGL Prototype and Protocol Refresh

This phase updates the Wayland protocol bindings to the latest upstream XMLs and delivers a runnable EGL + OpenGL ES demo on Wayland. The goal is to establish a working GPU-rendered window on Manjaro with zero manual inputs so the team can see immediate visual output and build on a solid, regenerated protocol foundation.

## Tasks

- [x] Update `packages/client/protocols.yaml` to ensure every protocol points at the latest `main` branch XML URLs and includes any missing upstream protocol entries since the last sync
  - Added newly tracked staging protocols (color management/representation, commit timing, ext background/data control, ext image capture/copy, ext workspace, fifo, pointer warp, xdg system bell, xdg toplevel tag) and unstable protocols (tablet v2, text input v3, xdg foreign v2) from upstream main.
- [ ] Run the existing scanner/codegen pipeline to regenerate protocol bindings for all listed protocols and commit the updated Dart sources
  - Blocked: `dart` is not available in this environment (`dart --enable-asserts bin/scanner.dart scan ...` fails with "command not found"). Install or expose the Dart SDK to run the scanner.
  - Rechecked: `dart --version` still reports "command not found" in this environment.
- [ ] Add `libwayland-egl` FFI bindings under `packages/gl/ffi/wayland_egl.yaml` and generate Dart bindings alongside existing EGL/GL bindings
- [ ] Create a small EGL setup helper in `packages/gl/lib/src/egl/wayland_egl.dart` that opens `libEGL.so.1`, creates an EGL display from a Wayland display, and builds a window surface from `wl_egl_window`
- [ ] Add a minimal `EglWindow` wrapper in `packages/window_toolkit/lib/src/egl/egl_window.dart` that manages `wl_egl_window`, EGL context, and surface lifecycle
- [ ] Implement a runnable demo at `packages/window_toolkit/example/egl_clear.dart` that opens a Wayland window, initializes EGL+GLES2, clears to a solid color, and swaps buffers in a frame loop
- [ ] Wire the new EGL example into `packages/window_toolkit/example/` README or main example index so it is discoverable and has a single command to run
- [ ] Validate the prototype by running the example on Manjaro and ensure a window appears with the expected clear color
