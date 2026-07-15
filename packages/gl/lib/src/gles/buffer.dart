import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import '../bindings/gles2_binding.dart' as g2;

const _GL_ARRAY_BUFFER = 0x8892;
const _GL_STATIC_DRAW = 0x88E4;
const _GL_DYNAMIC_DRAW = 0x88E8;
const _GL_FLOAT = 0x1406;

/// OpenGL ES 2.0 vertex buffer object (VBO).
///
/// Manages a GPU-side buffer for vertex data. Automatically allocates
/// and frees the native memory for data upload.
///
/// ```dart
/// final vbo = VertexBuffer()
///   ..setData(Float32List.fromList([...]), GL_STATIC_DRAW)
///   ..attribPointer(aPos, 2, GL_FLOAT, false, 0, 0)
///   ..enable(aPos)
///   ..drawArrays(GL_TRIANGLES, 0, 3);
/// ```
class VertexBuffer {
  final g2.GLES2 _gles2;
  final Pointer<g2.GLuint> _handlePtr;

  /// The raw GL buffer handle.
  int get handle => _handlePtr.value;

  VertexBuffer() : _gles2 = _gles2Singleton2, _handlePtr = calloc<g2.GLuint>(1) {
    _gles2.glGenBuffers(1, _handlePtr);
  }

  /// Upload vertex data to the GPU.
  ///
  /// [data] is a [Float32List] of interleaved vertex attributes.
  /// [usage] is one of GL_STATIC_DRAW, GL_DYNAMIC_DRAW, GL_STREAM_DRAW.
  void setData(Float32List data, {int usage = _GL_STATIC_DRAW}) {
    final ptr = calloc<Float>(data.length);
    for (var i = 0; i < data.length; i++) ptr[i] = data[i];
    _gles2.glBindBuffer(_GL_ARRAY_BUFFER, _handlePtr.value);
    _gles2.glBufferData(_GL_ARRAY_BUFFER, data.length * 4, ptr.cast(), usage);
    calloc.free(ptr);
  }

  /// Bind this buffer as the current GL_ARRAY_BUFFER.
  void bind() {
    _gles2.glBindBuffer(_GL_ARRAY_BUFFER, _handlePtr.value);
  }

  /// Set up a vertex attribute pointer for the currently bound buffer.
  void attribPointer(int location, int size, int type, bool normalized, int stride, int offset) {
    _gles2.glVertexAttribPointer(
      location, size, type, normalized ? 1 : 0, stride,
      Pointer<Void>.fromAddress(offset),
    );
  }

  void enable(int location) => _gles2.glEnableVertexAttribArray(location);
  void disable(int location) => _gles2.glDisableVertexAttribArray(location);

  void drawArrays(int mode, int first, int count) => _gles2.glDrawArrays(mode, first, count);

  void unbind() => _gles2.glBindBuffer(_GL_ARRAY_BUFFER, 0);

  void dispose() {
    if (_handlePtr.value != 0) {
      _gles2.glDeleteBuffers(1, _handlePtr);
    }
    calloc.free(_handlePtr);
  }
}

final g2.GLES2 _gles2Singleton2 = () {
  final lib = DynamicLibrary.open('libGLESv2.so.2');
  return g2.GLES2(lib);
}();
