/// Which [Painter] backend to use for rendering.
enum RendererBackend {
  /// Try GLES2 first, then Skia, then software (RawPainter).
  auto,
  /// GPU-accelerated via GLES2. Throws if unavailable.
  gl,
  /// GPU-accelerated via Skia. Falls back to RawPainter.
  skia,
}
