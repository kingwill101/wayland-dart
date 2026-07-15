/// Minimal GL initialization example using the high-level wrapper.
///
/// Creates an EGL context with a PBuffer, clears the screen to red,
/// reads back the pixel, and prints it. No window or Wayland needed.
library;

import 'dart:io';

import 'package:gl/gl.dart';

void main() {
  // Create an 8-bit RGBA offscreen context (1×1).
  final gl = GL.create();

  gl.clearColor(1.0, 0.0, 0.0, 1.0);
  gl.clear();

  // Read the single pixel back.
  final pixels = gl.readPixelsAll();
  stderr.writeln('Pixel 0 = RGBA(${pixels[0]}, ${pixels[1]}, ${pixels[2]}, ${pixels[3]})');
  stderr.writeln('Expected: RGBA(255, 0, 0, 255)');

  gl.dispose();
  stderr.writeln('OK');
}
