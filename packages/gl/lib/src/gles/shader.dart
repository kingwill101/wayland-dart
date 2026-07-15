import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../bindings/gles2_binding.dart' as g2;

const _GL_FRAGMENT_SHADER = 0x8B30;
const _GL_VERTEX_SHADER = 0x8B31;
const _GL_COMPILE_STATUS = 0x8B81;
const _GL_INFO_LOG_LENGTH = 0x8B84;
const _GL_LINK_STATUS = 0x8B82;

/// Compiled GLSL shader.
///
/// ```dart
/// final vs = Shader.vertex('attribute vec2 aPos; void main() { ... }');
/// ```
class Shader {
  final int _handle;
  final g2.GLES2 _gles2;

  /// Compile a vertex shader from [source].
  factory Shader.vertex(String source) {
    final gles2 = _gles2Singleton;
    final handle = gles2.glCreateShader(_GL_VERTEX_SHADER);
    if (handle == 0) throw Exception('glCreateShader failed');
    return Shader._create(handle, gles2, source);
  }

  /// Compile a fragment shader from [source].
  factory Shader.fragment(String source) {
    final gles2 = _gles2Singleton;
    final handle = gles2.glCreateShader(_GL_FRAGMENT_SHADER);
    if (handle == 0) throw Exception('glCreateShader failed');
    return Shader._create(handle, gles2, source);
  }

  Shader._create(this._handle, this._gles2, String source) {

    final srcPtr = source.toNativeUtf8().cast<g2.GLchar>();
    final srcArray = calloc<Pointer<g2.GLchar>>(1)..[0] = srcPtr;
    final len = source.length;
    final lenPtr = calloc<g2.GLint>(1)..value = len;
    _gles2.glShaderSource(_handle, 1, srcArray, lenPtr);
    calloc.free(srcArray);
    calloc.free(srcPtr);
    calloc.free(lenPtr);

    _gles2.glCompileShader(_handle);

    // Check compile status.
    final statusPtr = calloc<g2.GLint>(1);
    _gles2.glGetShaderiv(_handle, _GL_COMPILE_STATUS, statusPtr);
    if (statusPtr.value == 0) {
      final log = _getShaderInfoLog();
      calloc.free(statusPtr);
      throw Exception('Shader compile error: $log');
    }
    calloc.free(statusPtr);
  }

  String _getShaderInfoLog() {
    final lenPtr = calloc<g2.GLint>(1);
    _gles2.glGetShaderiv(_handle, _GL_INFO_LOG_LENGTH, lenPtr);
    final logLen = lenPtr.value;
    calloc.free(lenPtr);
    if (logLen <= 0) return '(unknown)';
    final buf = calloc<g2.GLchar>(logLen);
    _gles2.glGetShaderInfoLog(_handle, logLen, nullptr, buf);
    final result = buf.cast<Utf8>().toDartString();
    calloc.free(buf);
    return result;
  }

  /// The raw GL shader handle.
  int get handle => _handle;

  /// Release the shader.
  void dispose() {
    _gles2.glDeleteShader(_handle);
  }
}

/// Linked GLSL shader program with uniform/attribute lookup helpers.
///
/// ```dart
/// final prog = Program()
///   ..attach(vertexShader)
///   ..attach(fragmentShader)
///   ..link()
///   ..use();
/// final aPos = prog.getAttribLocation('aPos');
/// final uColor = prog.getUniformLocation('uColor');
/// ```
class Program {
  final int _handle;
  final g2.GLES2 _gles2;
  bool _linked = false;

  /// Create an empty program.
  Program() : _handle = _createProgram(), _gles2 = _gles2Singleton;

  static int _createProgram() {
    final h = _gles2Singleton.glCreateProgram();
    if (h == 0) throw Exception('glCreateProgram failed');
    return h;
  }

  /// Attach a compiled shader.
  void attach(Shader shader) {
    _gles2.glAttachShader(_handle, shader.handle);
  }

  /// Link the program.
  void link() {
    _gles2.glLinkProgram(_handle);

    final statusPtr = calloc<g2.GLint>(1);
    _gles2.glGetProgramiv(_handle, _GL_LINK_STATUS, statusPtr);
    if (statusPtr.value == 0) {
      final log = _getProgramInfoLog();
      calloc.free(statusPtr);
      throw Exception('Program link error: $log');
    }
    calloc.free(statusPtr);
    _linked = true;
  }

  String _getProgramInfoLog() {
    final lenPtr = calloc<g2.GLint>(1);
    _gles2.glGetProgramiv(_handle, _GL_INFO_LOG_LENGTH, lenPtr);
    final logLen = lenPtr.value;
    calloc.free(lenPtr);
    if (logLen <= 0) return '(unknown)';
    final buf = calloc<g2.GLchar>(logLen);
    _gles2.glGetProgramInfoLog(_handle, logLen, nullptr, buf);
    final result = buf.cast<Utf8>().toDartString();
    calloc.free(buf);
    return result;
  }

  /// Use this program for rendering.
  void use() {
    _gles2.glUseProgram(_handle);
  }

  /// Get the location of an attribute variable.
  int getAttribLocation(String name) {
    final ptr = name.toNativeUtf8().cast<g2.GLchar>();
    final loc = _gles2.glGetAttribLocation(_handle, ptr);
    calloc.free(ptr);
    return loc;
  }

  /// Get the location of a uniform variable.
  int getUniformLocation(String name) {
    final ptr = name.toNativeUtf8().cast<g2.GLchar>();
    final loc = _gles2.glGetUniformLocation(_handle, ptr);
    calloc.free(ptr);
    return loc;
  }

  /// The raw GL program handle.
  int get handle => _handle;

  /// Whether the program has been linked.
  bool get isLinked => _linked;

  /// Release the program.
  void dispose() {
    _gles2.glDeleteProgram(_handle);
    _linked = false;
  }
}

// Lazy singleton GLES2 binding — loaded once and shared.
final g2.GLES2 _gles2Singleton = () {
  final lib = DynamicLibrary.open('libGLESv2.so.2');
  return g2.GLES2(lib);
}();
