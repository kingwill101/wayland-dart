/// Platform-neutral contracts used by the window toolkit.
///
/// Concrete protocol implementations live below the backend packages. Widgets
/// and higher-level windows should depend on these contracts instead of
/// importing a protocol package directly.
library;

/// The input policy for a toolkit-managed surface.
enum SurfaceInputMode {
  /// The surface receives pointer input over its committed bounds.
  normal,

  /// The surface remains visible but does not receive pointer input.
  passthrough,
}

/// The event-loop portion of a platform connection.
abstract interface class PlatformConnection {
  bool get isConnected;

  void dispatch();

  void reset();
}

/// The lifecycle and input-policy portion of a native surface.
abstract interface class PlatformSurface {
  void setInputMode(SurfaceInputMode mode);

  void commit();

  void destroy();
}
