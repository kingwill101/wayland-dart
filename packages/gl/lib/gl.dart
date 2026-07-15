/// OpenGL ES 2.0 + EGL high-level Dart wrapper.
///
/// Usage:
/// ```dart
/// final gl = GL.create();  // initializes EGL with a PBuffer
/// gl.clearColor(0.1, 0.1, 0.15, 1.0);
/// gl.clear();
/// // ... draw with shaders, buffers ...
/// final pixels = gl.readPixels(width, height);
/// gl.dispose();
/// ```
library gl;

export 'src/bindings/egl_binding.dart';
export 'src/bindings/gles2_binding.dart'
    hide khronos_ssize_t, Dartkhronos_ssize_t;

export 'src/gles/gl.dart' show GL;
export 'src/gles/shader.dart' show Shader, Program;
export 'src/gles/buffer.dart' show VertexBuffer;
export 'src/gles/context.dart' show EglConfig;
export 'src/gles/texture.dart' show Texture;
