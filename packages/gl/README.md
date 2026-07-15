# OpenGL ES 2.0 + EGL bindings for Dart

High-level wrapper over raw `ffigen`-generated EGL/GLES2 bindings.
Manages all FFI memory allocation internally — no manual `calloc`/`free`.

## Usage

```dart
import 'package:gl/gl.dart';

final gl = GL.create(width: 800, height: 600);
gl.clearColor(0.1, 0.1, 0.15, 1.0);
gl.clear();

// Shaders
final vs = Shader.vertex('attribute vec2 aPos; void main() { ... }');
final fs = Shader.fragment('precision mediump float; void main() { ... }');
final prog = Program()..attach(vs)..attach(fs)..link()..use();
final aPos = prog.getAttribLocation('aPos');

// Vertex buffer
final vbo = VertexBuffer()
  ..setData(Float32List.fromList([-0.5, -0.5, 0.5, -0.5, 0.0, 0.5]))
  ..attribPointer(aPos, 2, GL_FLOAT, false, 0, 0)
  ..enable(aPos)
  ..drawArrays(GL_TRIANGLES, 0, 3);

// Read pixels back
final pixels = gl.readPixelsAll(); // Uint8List RGBA

gl.dispose();
```

## Classes

| Class | Description |
|-------|-------------|
| `GL` | EGL context + GLES2 state management, uniform setters, pixel readback |
| `Shader` | Compile vertex/fragment shaders with error checking |
| `Program` | Link shader programs, attribute/uniform location lookup |
| `VertexBuffer` | GPU buffer with `setData`, `attribPointer`, `drawArrays` |
| `Texture` | RGBA texture upload from pixel data (with nearest/linear filtering) |
| `EglConfig` | Framebuffer format config (bits, depth, stencil, samples) |

## Constants

Common GL constants (`GL_TRIANGLES`, `GL_FLOAT`, `GL_BLEND`, `GL_RGBA`, etc.)
are exported as top-level `int` constants.

Low-level `EGL` and `GLES2` classes with raw FFI function pointers are also
exported for advanced use cases.
