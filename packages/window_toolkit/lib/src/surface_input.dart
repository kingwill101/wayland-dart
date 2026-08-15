import 'package:wayland/wayland.dart';

import 'backend/connection.dart';

/// Pointer-input behavior for toolkit-managed surfaces.
///
/// This keeps surface hit-testing policy at the toolkit boundary. Applications
/// should not create compositor-specific input regions themselves.
enum SurfaceInputMode {
  /// The surface receives pointer input across its committed bounds.
  normal,

  /// The surface remains visible but does not receive pointer input.
  passthrough,
}

/// Applies the platform surface input policy for a Wayland-backed surface.
///
/// The native surface handle is intentionally accepted here rather than in
/// application code. A future non-Wayland backend can provide the equivalent
/// implementation without changing popup callers.
class SurfaceInputController {
  final WaylandConnection connection;

  const SurfaceInputController(this.connection);

  void setMode(WlSurface surface, SurfaceInputMode mode) {
    switch (mode) {
      case SurfaceInputMode.normal:
        // A newly-created Wayland surface already has the default full input
        // region. Existing callers should create a new surface when changing
        // back from passthrough until nullable regions are exposed uniformly.
        return;
      case SurfaceInputMode.passthrough:
        final region = connection.compositor.createRegion().getOrElse((e) {
          throw StateError('Unable to create passthrough input region: $e');
        });
        surface.setInputRegion(region);
        region.destroy();
    }
  }
}
