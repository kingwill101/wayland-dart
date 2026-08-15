import 'dart:io';

/// Which [Painter] backend to use for rendering.
enum RendererBackend {
  /// Try GLES2 first, then Skia, then software (RawPainter).
  auto,

  /// GPU-accelerated via GLES2. Throws if unavailable.
  gl,

  /// GPU-accelerated via Skia. Falls back to RawPainter.
  skia,

  /// GPU-accelerated via Skia Graphite and Dawn/WebGPU.
  dawn;

  /// Parses a backend name, defaulting to [auto] for missing/unknown values.
  static RendererBackend parse(String? value) {
    return switch (value?.trim().toLowerCase()) {
      'auto' => auto,
      'gl' || 'gles' || 'opengles' => gl,
      'skia' || 'raster' => skia,
      'dawn' || 'graphite' || 'webgpu' => dawn,
      _ => auto,
    };
  }

  /// Reads the process-wide renderer selection.
  ///
  /// The toolkit-wide variable is [WAYLAND_RENDERER_BACKEND].
  /// [BARDASH_BACKEND] remains accepted for existing Bardash launchers.
  static RendererBackend fromEnvironment() {
    return parse(
      Platform.environment['WAYLAND_RENDERER_BACKEND'] ??
          Platform.environment['BARDASH_BACKEND'],
    );
  }
}
