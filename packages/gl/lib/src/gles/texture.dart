import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

// ── GL constants for texture ops ─────────────────────────────────
const _TEXTURE_2D = 0x0DE1;
const _TEXTURE_MIN_FILTER = 0x2801;
const _TEXTURE_MAG_FILTER = 0x2800;
const _NEAREST = 0x2600;
const _LINEAR = 0x2601;
const _TEXTURE_WRAP_S = 0x2802;
const _TEXTURE_WRAP_T = 0x2803;
const _CLAMP_TO_EDGE = 0x812F;
const _UNPACK_ALIGNMENT = 0x0CF5;
const _ALPHA = 0x1906;
const _RGBA = 0x1908;
const _UNSIGNED_BYTE = 0x1401;

final DynamicLibrary _lib = DynamicLibrary.open('libGLESv2.so.2');

// ── FFI function types ───────────────────────────────────────────
typedef _GenTexturesNative = Void Function(Int32, Pointer<Uint32>);
typedef _GenTexturesDart = void Function(int, Pointer<Uint32>);
typedef _BindTextureNative = Void Function(Uint32, Uint32);
typedef _BindTextureDart = void Function(int, int);
typedef _DeleteTexturesNative = Void Function(Int32, Pointer<Uint32>);
typedef _DeleteTexturesDart = void Function(int, Pointer<Uint32>);
typedef _TexParameteriNative = Void Function(Uint32, Uint32, Int32);
typedef _TexParameteriDart = void Function(int, int, int);
typedef _PixelStoreiNative = Void Function(Uint32, Int32);
typedef _PixelStoreiDart = void Function(int, int);
typedef _TexImage2DNative = Void Function(
    Uint32, Int32, Int32, Int32, Int32, Int32, Uint32, Uint32, Pointer<Void>);
typedef _TexImage2DDart = void Function(
    int, int, int, int, int, int, int, int, Pointer<Void>);

final _genTextures = _lib
    .lookup<NativeFunction<_GenTexturesNative>>('glGenTextures')
    .asFunction<_GenTexturesDart>();
final _bindTexture = _lib
    .lookup<NativeFunction<_BindTextureNative>>('glBindTexture')
    .asFunction<_BindTextureDart>();
final _deleteTextures = _lib
    .lookup<NativeFunction<_DeleteTexturesNative>>('glDeleteTextures')
    .asFunction<_DeleteTexturesDart>();
final _texParameteri = _lib
    .lookup<NativeFunction<_TexParameteriNative>>('glTexParameteri')
    .asFunction<_TexParameteriDart>();
final _pixelStorei = _lib
    .lookup<NativeFunction<_PixelStoreiNative>>('glPixelStorei')
    .asFunction<_PixelStoreiDart>();
final _texImage2D = _lib
    .lookup<NativeFunction<_TexImage2DNative>>('glTexImage2D')
    .asFunction<_TexImage2DDart>();

/// A GLES2 texture.
class Texture {
  final int handle;
  final int width;
  final int height;

  /// Upload alpha-only data as an RGBA texture for consistent driver support.
  ///
  /// [data] is [width]×[height] alpha bytes (0=transparent, 255=opaque).
  /// If [smooth] is true, uses GL_LINEAR filtering.
  factory Texture.fromAlpha(Uint8List data, int width, int height,
      {bool smooth = false}) {
    final rgba = Uint8List(data.length * 4);
    for (var i = 0; i < data.length; i++) {
      rgba[i * 4] = data[i];
      rgba[i * 4 + 3] = 255;
    }
    return Texture.fromRgba(rgba, width, height, smooth: smooth);
  }

  /// Upload raw RGBA pixel data.
  ///
  /// If [smooth] is true, uses GL_LINEAR filtering (smoother scaling);
  /// otherwise GL_NEAREST (crisp pixel art, text at exact size).
  factory Texture.fromRgba(Uint8List data, int width, int height,
      {bool smooth = false}) {
    final handlePtr = calloc<Uint32>(1);
    _genTextures(1, handlePtr);
    final handle = handlePtr.value;
    calloc.free(handlePtr);

    _bindTexture(_TEXTURE_2D, handle);
    final filter = smooth ? _LINEAR : _NEAREST;
    _texParameteri(_TEXTURE_2D, _TEXTURE_MIN_FILTER, filter);
    _texParameteri(_TEXTURE_2D, _TEXTURE_MAG_FILTER, filter);
    _texParameteri(_TEXTURE_2D, _TEXTURE_WRAP_S, _CLAMP_TO_EDGE);
    _texParameteri(_TEXTURE_2D, _TEXTURE_WRAP_T, _CLAMP_TO_EDGE);
    _pixelStorei(_UNPACK_ALIGNMENT, 1);

    final ptr = calloc<Uint8>(data.length);
    for (var i = 0; i < data.length; i++) ptr[i] = data[i];
    _texImage2D(_TEXTURE_2D, 0, _RGBA, width, height, 0, _RGBA, _UNSIGNED_BYTE, ptr.cast());
    calloc.free(ptr);

    return Texture._(handle, width, height);
  }

  Texture._(this.handle, this.width, this.height);

  void bind() => _bindTexture(_TEXTURE_2D, handle);

  void dispose() {
    if (handle != 0) {
      _bindTexture(_TEXTURE_2D, 0);
      final ptr = calloc<Uint32>(1)..value = handle;
      _deleteTextures(1, ptr);
      calloc.free(ptr);
    }
  }
}
