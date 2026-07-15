import 'dart:ffi';
import 'dart:io' show stderr;
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import '../bindings/egl_binding.dart' as eb;
import '../bindings/gles2_binding.dart' as g2;
import 'context.dart';
import 'texture.dart' show Texture;

// ── GL constants ─────────────────────────────────────────────────
const GL_FALSE = 0;
const GL_TRUE = 1;

const GL_ZERO = 0;
const GL_ONE = 1;
const GL_SRC_ALPHA = 0x0302;
const GL_ONE_MINUS_SRC_ALPHA = 0x0303;
const GL_BLEND = 0x0BE2;
const GL_SCISSOR_TEST = 0x0C11;

const GL_COLOR_BUFFER_BIT = 0x00004000;
const GL_TRIANGLES = 0x0004;
const GL_TRIANGLE_FAN = 0x0006;
const GL_TRIANGLE_STRIP = 0x0005;
const GL_LINES = 0x0001;
const GL_FLOAT = 0x1406;
const GL_RGBA = 0x1908;
const GL_ARRAY_BUFFER = 0x8892;
const GL_STATIC_DRAW = 0x88E4;
const GL_DYNAMIC_DRAW = 0x88E8;
const GL_STREAM_DRAW = 0x88E0;
const GL_UNSIGNED_BYTE = 0x1401;
const GL_TEXTURE0 = 0x84C0;

const _EGL_DEFAULT_DISPLAY = 0;
const _EGL_NO_CONTEXT = 0;
const _EGL_NO_SURFACE = 0;
const _EGL_FALSE = 0;

const _EGL_ALPHA_SIZE = 0x3021;
const _EGL_BLUE_SIZE = 0x3022;
const _EGL_GREEN_SIZE = 0x3023;
const _EGL_RED_SIZE = 0x3024;
const _EGL_DEPTH_SIZE = 0x3025;
const _EGL_STENCIL_SIZE = 0x3026;
const _EGL_SAMPLES = 0x3031;
const _EGL_SURFACE_TYPE = 0x3033;
const _EGL_PBUFFER_BIT = 0x0001;
const _EGL_RENDERABLE_TYPE = 0x3040;
const _EGL_OPENGL_ES2_BIT = 0x0004;
const _EGL_NONE = 0x3038;
const _EGL_WIDTH = 0x3057;
const _EGL_HEIGHT = 0x3056;
const _EGL_CONTEXT_CLIENT_VERSION = 0x3098;
const _EGL_OPENGL_ES_API = 0x30A0;

/// High-level wrapper around EGL + GLES2.
///
/// All FFI memory management is handled internally. Provides a clean
/// Dart API for common rendering operations.
///
/// ```dart
/// final gl = GL.create(width: 800, height: 600);
/// gl.clearColor(0.1, 0.1, 0.15, 1.0);
/// gl.clear();
/// // ... draw with shaders, buffers ...
/// final pixels = gl.readPixelsAll();
/// gl.dispose();
/// ```
class GL {
  final Pointer<Void> _display;
  final Pointer<Void> _config;
  final Pointer<Void> _context;
  Pointer<Void> _surface;
  late final eb.EGL _egl;
  late final g2.GLES2 _gles2;
  int _width;
  int _height;
  bool _disposed = false;

  /// The raw GLES2 binding for advanced use.
  g2.GLES2 get gles2 => _gles2;
  /// The raw EGL binding for advanced use.
  eb.EGL get egl => _egl;
  Pointer<Void> get eglDisplay => _display;
  int get width => _width;
  int get height => _height;

  /// Create an EGL context with an offscreen PBuffer surface.
  ///
  /// [config] customises the framebuffer format (default: 8-bit RGBA).
  /// [width] and [height] set the initial PBuffer dimensions.
  factory GL.create({int width = 1, int height = 1, EglConfig config = const EglConfig()}) {
    final libEGL = DynamicLibrary.open('libEGL.so.1');
    final libGLESv2 = DynamicLibrary.open('libGLESv2.so.2');
    final egl = eb.EGL(libEGL);

    final display = egl.GetDisplay(Pointer<Void>.fromAddress(_EGL_DEFAULT_DISPLAY));
    if (display == nullptr) _fail('eglGetDisplay');

    final maj = calloc<eb.EGLint>(1);
    final min = calloc<eb.EGLint>(1);
    if (egl.Initialize(display, maj, min) == _EGL_FALSE) _fail('eglInitialize');
    calloc.free(maj);
    calloc.free(min);

    if (egl.BindAPI(_EGL_OPENGL_ES_API) == _EGL_FALSE) _fail('eglBindAPI');

    final cfgList = <int>[
      _EGL_SURFACE_TYPE, _EGL_PBUFFER_BIT,
      _EGL_RENDERABLE_TYPE, _EGL_OPENGL_ES2_BIT,
      _EGL_RED_SIZE, config.redBits,
      _EGL_GREEN_SIZE, config.greenBits,
      _EGL_BLUE_SIZE, config.blueBits,
      _EGL_ALPHA_SIZE, config.alphaBits,
      if (config.depthBits > 0) ...[_EGL_DEPTH_SIZE, config.depthBits],
      if (config.stencilBits > 0) ...[_EGL_STENCIL_SIZE, config.stencilBits],
      if (config.samples > 0) ...[_EGL_SAMPLES, config.samples],
      _EGL_NONE,
    ];
    final attribs = calloc<Int32>(cfgList.length);
    for (var i = 0; i < cfgList.length; i++) attribs[i] = cfgList[i];

    final cfgPtr = calloc<Pointer<Void>>(1);
    final numCfg = calloc<eb.EGLint>(1);
    if (egl.ChooseConfig(display, attribs, cfgPtr, 1, numCfg) == _EGL_FALSE || numCfg.value == 0) {
      calloc.free(attribs);
      calloc.free(cfgPtr);
      calloc.free(numCfg);
      _fail('eglChooseConfig');
    }
    final configPtr = cfgPtr[0];
    calloc.free(attribs);
    calloc.free(cfgPtr);
    calloc.free(numCfg);

    final pbAttribs = calloc<Int32>(5);
    pbAttribs[0] = _EGL_WIDTH;
    pbAttribs[1] = width;
    pbAttribs[2] = _EGL_HEIGHT;
    pbAttribs[3] = height;
    pbAttribs[4] = _EGL_NONE;
    final surface = egl.CreatePbufferSurface(display, configPtr, pbAttribs);
    calloc.free(pbAttribs);
    if (surface == nullptr) _fail('eglCreatePbufferSurface');

    final ctxAttribs = calloc<Int32>(3);
    ctxAttribs[0] = _EGL_CONTEXT_CLIENT_VERSION;
    ctxAttribs[1] = 2;
    ctxAttribs[2] = _EGL_NONE;
    final context = egl.CreateContext(
      display, configPtr, Pointer<Void>.fromAddress(_EGL_NO_CONTEXT), ctxAttribs,
    );
    calloc.free(ctxAttribs);
    if (context == nullptr) _fail('eglCreateContext');

    if (egl.MakeCurrent(display, surface, surface, context) == _EGL_FALSE) {
      _fail('eglMakeCurrent');
    }

    final gles2 = g2.GLES2(libGLESv2);
    gles2.glEnable(GL_BLEND);
    gles2.glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    gles2.glViewport(0, 0, width, height);

    return GL._(
      egl: egl,
      gles2: gles2,
      display: display,
      config: configPtr,
      context: context,
      surface: surface,
      width: width,
      height: height,
    );
  }

  GL._({
    required eb.EGL egl,
    required g2.GLES2 gles2,
    required Pointer<Void> display,
    required Pointer<Void> config,
    required Pointer<Void> context,
    required Pointer<Void> surface,
    required int width,
    required int height,
  })  : _egl = egl,
        _gles2 = gles2,
        _display = display,
        _config = config,
        _context = context,
        _surface = surface,
        _width = width,
        _height = height;

  // ── Lifecycle ──────────────────────────────────────────────────

  void makeCurrent() {
    _checkNotDisposed();
    _egl.MakeCurrent(_display, _surface, _surface, _context);
    _gles2.glViewport(0, 0, _width, _height);
  }

  void resize(int width, int height) {
    _checkNotDisposed();
    if (width == _width && height == _height) return;
    _egl.DestroySurface(_display, _surface);
    final pbAttribs = calloc<Int32>(5);
    pbAttribs[0] = _EGL_WIDTH;
    pbAttribs[1] = width;
    pbAttribs[2] = _EGL_HEIGHT;
    pbAttribs[3] = height;
    pbAttribs[4] = _EGL_NONE;
    _surface = _egl.CreatePbufferSurface(_display, _config, pbAttribs);
    calloc.free(pbAttribs);
    _width = width;
    _height = height;
    makeCurrent();
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _egl.MakeCurrent(
      _display,
      Pointer<Void>.fromAddress(_EGL_NO_SURFACE),
      Pointer<Void>.fromAddress(_EGL_NO_SURFACE),
      Pointer<Void>.fromAddress(_EGL_NO_CONTEXT),
    );
    if (_context != nullptr) _egl.DestroyContext(_display, _context);
    if (_surface != nullptr) _egl.DestroySurface(_display, _surface);
    _egl.Terminate(_display);
  }

  // ── State ──────────────────────────────────────────────────────

  void clearColor(double r, double g, double b, double a) => _gles2.glClearColor(r, g, b, a);
  void clear([int bits = GL_COLOR_BUFFER_BIT]) => _gles2.glClear(bits);
  void viewport(int x, int y, int w, int h) => _gles2.glViewport(x, y, w, h);
  void enable(int cap) => _gles2.glEnable(cap);
  void disable(int cap) => _gles2.glDisable(cap);
  void blendFunc(int sf, int df) => _gles2.glBlendFunc(sf, df);
  void scissor(int x, int y, int w, int h) => _gles2.glScissor(x, y, w, h);
  void activeTexture(int unit) => _gles2.glActiveTexture(unit);

  // ── Drawing ────────────────────────────────────────────────────

  void drawArrays(int mode, int first, int count) => _gles2.glDrawArrays(mode, first, count);
  void enableVertexAttrib(int index) => _gles2.glEnableVertexAttribArray(index);
  void disableVertexAttrib(int index) => _gles2.glDisableVertexAttribArray(index);

  void vertexAttribPointer(int index, int size, int type, bool normalized, int stride, int offset) {
    _gles2.glVertexAttribPointer(
      index, size, type, normalized ? GL_TRUE : 0, stride,
      Pointer<Void>.fromAddress(offset),
    );
  }

  // ── Uniforms ───────────────────────────────────────────────────

  void uniform1f(int loc, double v0) => _gles2.glUniform1f(loc, v0);
  void uniform2f(int loc, double v0, double v1) => _gles2.glUniform2f(loc, v0, v1);
  void uniform3f(int loc, double v0, double v1, double v2) => _gles2.glUniform3f(loc, v0, v1, v2);
  void uniform4f(int loc, double v0, double v1, double v2, double v3) =>
      _gles2.glUniform4f(loc, v0, v1, v2, v3);
  void uniform1i(int loc, int v0) => _gles2.glUniform1i(loc, v0);
  void uniform2i(int loc, int v0, int v1) => _gles2.glUniform2i(loc, v0, v1);
  void uniform3i(int loc, int v0, int v1, int v2) => _gles2.glUniform3i(loc, v0, v1, v2);
  void uniform4i(int loc, int v0, int v1, int v2, int v3) => _gles2.glUniform4i(loc, v0, v1, v2, v3);

  // ── Pixel readback ─────────────────────────────────────────────

  Uint8List readPixels(int x, int y, int w, int h) {
    final count = w * h * 4;
    final ptr = calloc<Uint8>(count);
    _gles2.glReadPixels(x, y, w, h, GL_RGBA, GL_UNSIGNED_BYTE, ptr.cast());
    final result = ptr.asTypedList(count);
    final copy = Uint8List.fromList(result);
    calloc.free(ptr);
    return copy;
  }

  Uint8List readPixelsAll() => readPixels(0, 0, _width, _height);

  // ── Error handling ─────────────────────────────────────────────

  String? checkError() {
    final err = _gles2.glGetError();
    switch (err) {
      case 0: return null;
      case 0x0500: return 'GL_INVALID_ENUM';
      case 0x0501: return 'GL_INVALID_VALUE';
      case 0x0502: return 'GL_INVALID_OPERATION';
      case 0x0505: return 'GL_OUT_OF_MEMORY';
      default: return 'GL_ERROR_0x${err.toRadixString(16)}';
    }
  }

  void _checkNotDisposed() {
    if (_disposed) throw StateError('GL context is disposed');
  }

  static Never _fail(String msg) {
    stderr.writeln('[gl] ERROR: $msg');
    throw Exception('GL: $msg');
  }
}
