import 'dart:ffi';
import 'dart:io' show stderr;
import 'dart:math';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:gl/gl.dart';
import 'package:skia_dart/skia_dart.dart';
import 'package:wayland/wayland.dart';

import '../drawing/color.dart';
import '../drawing/raster_image.dart';
import '../font/font.dart';
import '../font/font_database.dart';
import 'painter.dart';

/// Shared resources reused across all [GlesPainter] instances (context + shaders).
class _GlesShared {
  final GL gl;
  final Program rectProgram;
  final Program rrectProgram;
  final Program textProgram;
  late final int aPos = rectProgram.getAttribLocation('aPos');
  late final int uColor = rectProgram.getUniformLocation('uColor');
  late final int aRRPos = rrectProgram.getAttribLocation('aPos');
  late final int uRRColor = rrectProgram.getUniformLocation('uColor');
  late final int uRRRect = rrectProgram.getUniformLocation('uRect');
  late final int uRRRadius = rrectProgram.getUniformLocation('uRadius');
  late final int uRRHeight = rrectProgram.getUniformLocation('uHeight');
  late final int aTexPos = textProgram.getAttribLocation('aPos');
  late final int aTexCoord = textProgram.getAttribLocation('aTexCoord');
  late final int uTexColor = textProgram.getUniformLocation('uColor');
  late final int uTexture = textProgram.getUniformLocation('uTexture');
  final Program imageProgram;
  final Program gradProgram;

  late final int aImgPos = imageProgram.getAttribLocation('aPos');
  late final int aImgTexCoord = imageProgram.getAttribLocation('aTexCoord');
  late final int uImgTex = imageProgram.getUniformLocation('uTexture');
  late final int aGradPos = gradProgram.getAttribLocation('aPos');
  late final int uGradColor0 = gradProgram.getUniformLocation('uColor0');
  late final int uGradColor1 = gradProgram.getUniformLocation('uColor1');
  late final int uGradRect = gradProgram.getUniformLocation('uRect');
  late final int uGradAngle = gradProgram.getUniformLocation('uAngle');


  _GlesShared()
      : gl = GL.create(width: 1, height: 1),
        rectProgram = _buildRectProgram(),
        rrectProgram = _buildRRectProgram(),
        textProgram = _buildTextProgram(),
        imageProgram = _buildImageProgram(),
        gradProgram = _buildGradProgram() {
    rectProgram.use();
  }

  static Program _buildRectProgram() {
    return Program()
      ..attach(Shader.vertex(
        'attribute vec2 aPos;'
        'void main() { gl_Position = vec4(aPos, 0.0, 1.0); }',
      ))
      ..attach(Shader.fragment(
        'precision mediump float;'
        'uniform vec4 uColor;'
        'void main() { gl_FragColor = uColor; }',
      ))
      ..link();
  }

  static Program _buildRRectProgram() {
    return Program()
      ..attach(Shader.vertex(
        'attribute vec2 aPos;'
        'void main() { gl_Position = vec4(aPos, 0.0, 1.0); }',
      ))
      ..attach(Shader.fragment(
        'precision mediump float;'
        'uniform vec4 uColor;'
        'uniform vec4 uRect;'   // screen (l, t, r, b)
        'uniform vec2 uRadius;' // screen (rx, ry)
        'uniform float uHeight;' // screen height
        'void main() {'
        '  vec2 sp = vec2(gl_FragCoord.x, uHeight - gl_FragCoord.y);'
        '  vec2 halfSize = (uRect.zw - uRect.xy) * 0.5;'
        '  vec2 center = (uRect.xy + uRect.zw) * 0.5;'
        '  vec2 r = min(uRadius, halfSize);'
        '  vec2 p = abs(sp - center) - halfSize + r;'
        '  float d = length(max(p, 0.0)) + min(max(p.x, p.y), 0.0) - min(r.x, r.y);'
        '  float a = 1.0 - smoothstep(-0.5, 1.5, max(d, 0.0));'
        '  gl_FragColor = vec4(uColor.rgb, uColor.a * a);'
        '}',
      ))
      ..link();
  }

  static Program _buildGradProgram() {
    return Program()
      ..attach(Shader.vertex(
        'attribute vec2 aPos;'
        'void main() { gl_Position = vec4(aPos, 0.0, 1.0); }',
      ))
      ..attach(Shader.fragment(
        'precision mediump float;'
        'uniform vec4 uColor0;'
        'uniform vec4 uColor1;'
        'uniform vec4 uRect;'    // screen (l, t, r, b)
        'uniform float uAngle;'  // radians
        'void main() {'
        '  vec2 pos = gl_FragCoord.xy - uRect.xy;'
        '  vec2 dim = uRect.zw - uRect.xy;'
        '  float ca = cos(uAngle);'
        '  float sa = sin(uAngle);'
        '  float t = (pos.x * ca + pos.y * sa) / (dim.x * ca + dim.y * sa);'
        '  t = clamp(t, 0.0, 1.0);'
        '  gl_FragColor = mix(uColor0, uColor1, t);'
        '}',
      ))
      ..link();
  }

  static Program _buildImageProgram() {
    return Program()
      ..attach(Shader.vertex(
        'attribute vec2 aPos;'
        'attribute vec2 aTexCoord;'
        'varying vec2 vTexCoord;'
        'void main() {'
        '  gl_Position = vec4(aPos, 0.0, 1.0);'
        '  vTexCoord = aTexCoord;'
        '}',
      ))
      ..attach(Shader.fragment(
        'precision mediump float;'
        'varying vec2 vTexCoord;'
        'uniform sampler2D uTexture;'
        'void main() {'
        '  gl_FragColor = texture2D(uTexture, vTexCoord);'
        '}',
      ))
      ..link();
  }

  static Program _buildTextProgram() {
    final vs = Shader.vertex(
      'attribute vec2 aPos;'
      'attribute vec2 aTexCoord;'
      'varying vec2 vTexCoord;'
      'void main() {'
      '  gl_Position = vec4(aPos, 0.0, 1.0);'
      '  vTexCoord = aTexCoord;'
      '}',
    );
    final fs = Shader.fragment(
      'precision mediump float;'
      'varying vec2 vTexCoord;'
      'uniform vec4 uColor;'
      'uniform sampler2D uTexture;'
      'void main() {'
      '  float a = texture2D(uTexture, vTexCoord).r;'
      '  gl_FragColor = vec4(uColor.rgb, uColor.a * a);'
      '}',
    );
    return (Program()
      ..attach(vs)
      ..attach(fs)
      ..link());
  }
}

_GlesShared? _shared;

/// OpenGL ES 2.0 backend for [Painter].
///
/// GPU-accelerated via EGL offscreen PBuffer. Pixels are read back with
/// [GL.readPixelsAll] on each [flush] and written to the Wayland SHM fd.
///
/// Falls back to software rendering if GL initialization fails.
class GlesPainter implements Painter {
  final int _width;
  final int _height;
  final int fd;

  _GlesShared? _gles;
  VertexBuffer? _vbo;
  bool _disposed = false;
  bool _failed = false;

  // Screen → clip-space scale factors.
  final double _sx;
  final double _sy;

  // Scissor stack.
  final List<Rect?> _clips = [null];

  // Affine transform stack [a, b, c, d, tx, ty] (row-major 2x3).
  final List<Float64List> _matrixStack = [];
  Float64List _currentMatrix = Float64List(6);

  // Apply current affine transform to (x, y), return (x', y').
  // Identity matrix is [1, 0, 0, 1, 0, 0].
  // Transformed: x' = a*x + c*y + tx,  y' = b*x + d*y + ty.
  (double, double) _transform(double x, double y) {
    final m = _currentMatrix;
    return (m[0] * x + m[2] * y + m[4],
            m[1] * x + m[3] * y + m[5]);
  }

  /// Screen (x, y) → clip-space (cx, cy) with current transform applied.
  (double, double) _toClip(double x, double y) {
    final (tx, ty) = _transform(x, y);
    return (tx * _sx - 1, 1 - ty * _sy);
  }

  @override
  double get width => _width.toDouble();
  @override
  double get height => _height.toDouble();
  @override
  Size get size => Size(width, height);

  GlesPainter(this.fd, int width, int height)
      : _width = width,
        _height = height,
        _sx = 2.0 / width,
        _sy = 2.0 / height {
    _currentMatrix = Float64List(6);
    _currentMatrix[0] = 1; // identity
    _currentMatrix[3] = 1;
    _matrixStack.add(_currentMatrix);
    try {
      _shared ??= _GlesShared();
      _gles = _shared;
      _gles!.gl.resize(width, height);
      if (!_gles!.gl.makeCurrent()) {
        throw Exception('EGL context lost');
      }
      _gles!.gl.viewport(0, 0, width, height);
      _gles!.gl.enable(GL_BLEND);
      _gles!.gl.blendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
      _vbo = VertexBuffer();
    } catch (e) {
      stderr.writeln('[wt:gles] init failed: $e');
      _failed = true;
    }
  }

  // ── Internal helpers ───────────────────────────────────────────

  /// Convert four screen-space corners to clip-space [Float32List].
  void _drawVerts(Float32List verts, int mode) {
    final g = _gles!;
    final vbo = _vbo!;
    vbo.setData(verts, usage: GL_STREAM_DRAW);
    vbo.bind();
    vbo.attribPointer(g.aPos, 2, GL_FLOAT, false, 0, 0);
    g.gl.enableVertexAttrib(g.aPos);
    _applyScissor();
    vbo.drawArrays(mode, 0, verts.length ~/ 2);
  }

  void _applyScissor() {
    final clip = _clips.last;
    if (clip != null) {
      _gles!.gl.enable(GL_SCISSOR_TEST);
      _gles!.gl.scissor(
        clip.left.round(),
        (_height - clip.bottom).round(),
        clip.width.round(),
        clip.height.round(),
      );
    } else {
      _gles!.gl.disable(GL_SCISSOR_TEST);
    }
  }

  List<double> _glColor(Color c) =>
      [c.r / 255.0, c.g / 255.0, c.b / 255.0, c.a / 255.0];

  // ── Text texture cache ───────────────────────────────────────────
  // Cache rendered text textures so repeated strings (clock, module
  // labels) don't create a new SkSurface + GL texture every frame.
  static const int _maxTextCache = 128;
  final Map<String, _TextCacheEntry> _textCache = {};
  final List<String> _textCacheOrder = [];

  _TextCacheEntry? _cachedText(String text, double size, String font) {
    final key = '$font|${size.toStringAsFixed(1)}|$text';
    return _textCache[key];
  }

  void _cacheText(String text, double size, String font, _TextCacheEntry entry) {
    final key = '$font|${size.toStringAsFixed(1)}|$text';
    if (_textCache.length >= _maxTextCache) {
      final oldest = _textCacheOrder.removeAt(0);
      _textCache.remove(oldest)?.tex.dispose();
    }
    _textCache[key] = entry;
    _textCacheOrder.add(key);
  }

  /// Clear the text cache (call when font configuration changes).
  void clearTextCache() {
    for (final e in _textCache.values) e.tex.dispose();
    _textCache.clear();
    _textCacheOrder.clear();
  }

  /// Returns true if this painter's GL context is still usable.
  /// Call after catching GL errors to decide whether to fall back.
  bool get isHealthy => !_failed && !_disposed && _gles != null;

  // ── Painter interface ──────────────────────────────────────────

  @override
  void clear(Color color) {
    if (_failed) return;
    final c = _glColor(color);
    _gles!.gl.clearColor(c[0], c[1], c[2], c[3]);
    _gles!.gl.clear();
  }

  @override
  void drawRect(Rect rect, Paint paint) {
    if (_failed || _disposed) return;
    _gles!.rectProgram.use();
    if (paint.style == PaintStyle.stroke) {
      _drawRectStroke(rect, paint);
    } else {
      _drawRectFill(rect, paint);
    }
  }

  void _drawRectFill(Rect rect, Paint paint) {
    final c = _glColor(paint.color);
    _gles!.gl.uniform4f(_gles!.uColor, c[0], c[1], c[2], c[3]);
    final (l, t) = _toClip(rect.left, rect.top);
    final (r, b) = _toClip(rect.right, rect.bottom);
    _drawVerts(Float32List.fromList([l, t, r, t, r, b, l, b]), GL_TRIANGLE_FAN);
  }

  void _drawRectStroke(Rect rect, Paint paint) {
    final sw = paint.strokeWidth;
    if (sw <= 0) return;
    // Four thin rects for the border edges.
    final edges = [
      Rect.fromLTRB(rect.left, rect.top, rect.right, rect.top + sw),    // top
      Rect.fromLTRB(rect.left, rect.bottom - sw, rect.right, rect.bottom), // bottom
      Rect.fromLTRB(rect.left, rect.top, rect.left + sw, rect.bottom),     // left
      Rect.fromLTRB(rect.right - sw, rect.top, rect.right, rect.bottom),   // right
    ];
    for (final e in edges) { _drawRectFill(e, paint); }
  }

  @override
  void drawCircle(Offset center, double radius, Paint paint) {
    if (_failed || _disposed) return;
    if (paint.style == PaintStyle.stroke) {
      _drawCircleStroke(center, radius, paint);
    } else {
      _drawCircleFill(center, radius, paint);
    }
  }

  void _drawCircleFill(Offset center, double radius, Paint paint) {
    final c = _glColor(paint.color);
    _gles!.rectProgram.use();
    _gles!.gl.uniform4f(_gles!.uColor, c[0], c[1], c[2], c[3]);

    final (ccx, ccy) = _toClip(center.dx, center.dy);
    const segs = 32;
    final verts = Float32List((segs + 2) * 2);
    verts[0] = ccx; verts[1] = ccy;
    final r = radius * (_sx + _sy) * 0.5;
    for (var i = 0; i <= segs; i++) {
      final a = i * 2 * pi / segs;
      verts[(i + 1) * 2] = ccx + cos(a) * r;
      verts[(i + 1) * 2 + 1] = ccy + sin(a) * r;
    }
    _drawVerts(verts, GL_TRIANGLE_FAN);
  }

  void _drawCircleStroke(Offset center, double radius, Paint paint) {
    final c = _glColor(paint.color);
    final sw = paint.strokeWidth;
    if (sw <= 0) return;
    _gles!.rectProgram.use();
    _gles!.gl.uniform4f(_gles!.uColor, c[0], c[1], c[2], c[3]);

    final (ccx, ccy) = _toClip(center.dx, center.dy);
    const segs = 32;
    final r = radius * (_sx + _sy) * 0.5;
    final r2 = (radius + sw) * (_sx + _sy) * 0.5;
    // Triangle strip: inner and outer rings
    final verts = Float32List((segs + 1) * 4);
    for (var i = 0; i <= segs; i++) {
      final a = i * 2 * pi / segs;
      final ca = cos(a); final sa = sin(a);
      verts[i * 4] = ccx + ca * r;
      verts[i * 4 + 1] = ccy + sa * r;
      verts[i * 4 + 2] = ccx + ca * r2;
      verts[i * 4 + 3] = ccy + sa * r2;
    }
    _gles!.gl.vertexAttribPointer(_gles!.aPos, 2, GL_FLOAT, false, 0, 0);
    _gles!.gl.enableVertexAttrib(_gles!.aPos);
    for (var i = 0; i < segs; i++) {
      _gles!.gl.drawArrays(GL_TRIANGLE_STRIP, i * 2, 4);
    }
  }

  @override
  void drawLine(Offset from, Offset to, Paint paint) {
    if (_failed || _disposed) return;
    final c = _glColor(paint.color);

    final (x1, y1) = _toClip(from.dx, from.dy);
    final (x2, y2) = _toClip(to.dx, to.dy);
    final dx = x2 - x1;
    final dy = y2 - y1;
    final len = sqrt(dx * dx + dy * dy);
    if (len < 0.001) return;
    final nx = -dy / len * (paint.strokeWidth / _width);
    final ny = dx / len * (paint.strokeWidth / _height);

    _gles!.rectProgram.use();
    _gles!.gl.uniform4f(_gles!.uColor, c[0], c[1], c[2], c[3]);
    _drawVerts(Float32List.fromList([
      x1 + nx, y1 + ny,  x2 + nx, y2 + ny,
      x2 - nx, y2 - ny,  x1 - nx, y1 - ny,
    ]), GL_TRIANGLE_FAN);
  }

  @override
  void drawRRect(Rect rect, double radiusX, double radiusY, Paint paint) {
    if (_failed || _disposed) return;
    final g = _gles!;
    final c = _glColor(paint.color);

    final (l, t) = _toClip(rect.left, rect.top);
    final (r, b) = _toClip(rect.right, rect.bottom);
    final verts = Float32List.fromList([l, b, r, b, r, t, l, t]);

    final vbo = VertexBuffer();
    vbo.setData(verts, usage: GL_STREAM_DRAW);
    vbo.bind();

    g.rrectProgram.use();
    g.gl.uniform4f(g.uRRColor, c[0], c[1], c[2], c[3]);
    g.gl.uniform4f(g.uRRRect,
        rect.left, rect.top,
        rect.right, rect.bottom);
    g.gl.uniform2f(g.uRRRadius,
        radiusX.clamp(0, rect.width * 0.5),
        radiusY.clamp(0, rect.height * 0.5));
    g.gl.uniform1f(g.uRRHeight, _height.toDouble());

    vbo.attribPointer(g.aRRPos, 2, GL_FLOAT, false, 0, 0);
    g.gl.enableVertexAttrib(g.aRRPos);

    _applyScissor();
    vbo.drawArrays(GL_TRIANGLE_FAN, 0, 4);
    vbo.dispose();
  }

  @override
  void drawLinearGradient(Rect rect, Color color0, Color color1,
      {double angle = 0.0}) {
    if (_failed || _disposed) return;
    final g = _gles!;
    final c0 = _glColor(color0);
    final c1 = _glColor(color1);

    final verts = Float32List.fromList([
      rect.left * _sx - 1, 1 - rect.bottom * _sy,
      rect.right * _sx - 1, 1 - rect.bottom * _sy,
      rect.right * _sx - 1, 1 - rect.top * _sy,
      rect.left * _sx - 1, 1 - rect.top * _sy,
    ]);
    final vbo = VertexBuffer();
    vbo.setData(verts, usage: GL_STREAM_DRAW);
    vbo.bind();

    g.gradProgram.use();
    g.gl.uniform4f(g.uGradColor0, c0[0], c0[1], c0[2], c0[3]);
    g.gl.uniform4f(g.uGradColor1, c1[0], c1[1], c1[2], c1[3]);
    g.gl.uniform4f(g.uGradRect,
        rect.left, rect.top,
        rect.right, rect.bottom);
    g.gl.uniform1f(g.uGradAngle, angle);

    vbo.attribPointer(g.aGradPos, 2, GL_FLOAT, false, 0, 0);
    g.gl.enableVertexAttrib(g.aGradPos);
    _applyScissor();
    vbo.drawArrays(GL_TRIANGLE_FAN, 0, 4);
    vbo.dispose();
  }

  @override
  void drawText(String text, Offset position,
      {Color? color, double size = 14, String fontFamily = 'sans'}) {
    if (_failed || _disposed || text.isEmpty) return;

    final g = _gles!;
    final c = _glColor(color ?? const Color(255, 255, 255));

    // Check cache first.
    final cacheKey = '$fontFamily|${size.toStringAsFixed(1)}|$text';
    final cached = _textCache[cacheKey];
    if (cached != null) {
      _drawTexturedQuad(cached.tex, cached.width, cached.height,
          position.dx, position.dy, g, c);
      return;
    }

    // Measure via the font database.
    final font = Font(family: fontFamily, pixelSize: size);
    final metrics = FontDatabase.instance.metrics(font);
    final advance = metrics.horizontalAdvance(text);
    final bounds = metrics.boundingRect(text);
    var tw = (advance > bounds.width ? advance : bounds.width).ceil() + 2;
    var th = bounds.height.ceil() + 2;
    if (tw <= 0 || th <= 0) { tw = 16; th = 16; }

    final img = RasterImage(tw, th);
    img.drawText(text, 0, (-bounds.top).roundToDouble(),
        font: font, color: const Color(255, 255, 255));
    final tex = img.toTexture();
    _textCache[cacheKey] = _TextCacheEntry(tex, tw.toDouble(), th.toDouble());

    final px = position.dx.roundToDouble();
    final py = position.dy.roundToDouble();
    final (l, t) = _toClip(px, py);
    final (r, b) = _toClip(px + tw.toDouble(), py + th.toDouble());
    final verts = Float32List(16);
    verts[0] = l;  verts[1] = b;  verts[2] = 0;  verts[3] = 1;
    verts[4] = r;  verts[5] = b;  verts[6] = 1;  verts[7] = 1;
    verts[8] = r;  verts[9] = t;  verts[10] = 1;  verts[11] = 0;
    verts[12] = l; verts[13] = t; verts[14] = 0;  verts[15] = 0;

    final vbo = VertexBuffer();
    vbo.setData(verts, usage: GL_STREAM_DRAW);
    vbo.bind();

    g.textProgram.use();
    g.gl.uniform4f(g.uTexColor, c[0], c[1], c[2], c[3]);
    g.gl.uniform1i(g.uTexture, 0);
    vbo.attribPointer(g.aTexPos, 2, GL_FLOAT, false, 16, 0);
    g.gl.enableVertexAttrib(g.aTexPos);
    vbo.attribPointer(g.aTexCoord, 2, GL_FLOAT, false, 16, 8);
    g.gl.enableVertexAttrib(g.aTexCoord);

    g.gl.activeTexture(0x84C0);
    tex.bind();
    _applyScissor();
    vbo.drawArrays(GL_TRIANGLE_FAN, 0, 4);

    vbo.dispose();
    tex.dispose();
  }

  @override
  Size measureText(String text, {double size = 14, String fontFamily = 'sans'}) {
    try {
      final metrics = FontDatabase.instance.metrics(
          Font(family: fontFamily, pixelSize: size));
      return Size(metrics.horizontalAdvance(text), metrics.height);
    } catch (_) {
      return Size(text.length * size * 0.6, size);
    }
  }

  @override
  double measureTextAdvance(String text, {double size = 14, String fontFamily = 'sans'}) {
    try {
      final metrics = FontDatabase.instance.metrics(
          Font(family: fontFamily, pixelSize: size));
      return metrics.horizontalAdvance(text);
    } catch (_) {
      return text.length * size * 0.6;
    }
  }

  @override
  Rect measureTextBounds(String text, {double size = 14, String fontFamily = 'sans'}) {
    try {
      final metrics = FontDatabase.instance.metrics(
          Font(family: fontFamily, pixelSize: size));
      return metrics.boundingRect(text);
    } catch (_) {
      return Rect.fromLTWH(0, 0, text.length * size * 0.6, size);
    }
  }

  @override
  void drawImage(String filePath, double x, double y, {double? width, double? height}) {
    if (_failed || _disposed) return;
    try {
      final data = SkData.fromFile(filePath);
      if (data == null) { _drawImgPlaceholder(x, y, width, height); return; }
      final image = SkImage.fromEncoded(data);
      data.dispose();
      if (image == null) { _drawImgPlaceholder(x, y, width, height); return; }

      final imgW = image.width;
      final imgH = image.height;
      final dstW = (width ?? imgW.toDouble()).round();
      final dstH = (height ?? imgH.toDouble()).round();
      if (dstW <= 0 || dstH <= 0) { image.dispose(); return; }

      // Render image to an SkSurface at target size.
      final info = SkImageInfo(
        width: dstW, height: dstH,
        colorType: SkColorType.rgba8888,
        alphaType: SkAlphaType.premul,
      );
      final surface = SkSurface.raster(info);
      if (surface == null) { image.dispose(); _drawImgPlaceholder(x, y, width, height); return; }

      surface.canvas.clear(SkColor(0x00000000));
      // Scale image to fit the target rect.
      final dstRect = SkRect.fromLTRB(0, 0, dstW.toDouble(), dstH.toDouble());
      surface.canvas.drawImageRect(
        image, dstRect,
        sampling: const SkSamplingOptions(),
      );
      image.dispose();

      // Read pixels back.
      final pixels = Uint8List(dstW * dstH * 4);
      final nativePixels = calloc<Uint8>(pixels.length);
      final ok = surface.readPixels(info, nativePixels.cast(), dstW * 4, srcX: 0, srcY: 0);
      surface.dispose();
      if (ok) {
        for (var i = 0; i < pixels.length; i++) pixels[i] = nativePixels[i];
      }
      calloc.free(nativePixels);
      if (!ok) { _drawImgPlaceholder(x, y, width, height); return; }

      // Upload as GL texture and draw textured quad.
      final tex = Texture.fromRgba(pixels, dstW, dstH, smooth: true);
      final g = _gles!;
      final (l, t) = _toClip(x, y);
      final (r, b) = _toClip(x + dstW.toDouble(), y + dstH.toDouble());
      final verts = Float32List(16);
      verts[0] = l;  verts[1] = b;  verts[2] = 0;  verts[3] = 1;
      verts[4] = r;  verts[5] = b;  verts[6] = 1;  verts[7] = 1;
      verts[8] = r;  verts[9] = t;  verts[10] = 1;  verts[11] = 0;
      verts[12] = l; verts[13] = t; verts[14] = 0;  verts[15] = 0;

      final vbo = VertexBuffer();
      vbo.setData(verts, usage: GL_STREAM_DRAW);
      vbo.bind();
      g.imageProgram.use();
      g.gl.uniform1i(g.uImgTex, 0);
      vbo.attribPointer(g.aImgPos, 2, GL_FLOAT, false, 16, 0);
      g.gl.enableVertexAttrib(g.aImgPos);
      vbo.attribPointer(g.aImgTexCoord, 2, GL_FLOAT, false, 16, 8);
      g.gl.enableVertexAttrib(g.aImgTexCoord);
      g.gl.activeTexture(0x84C0);
      tex.bind();
      _applyScissor();
      vbo.drawArrays(GL_TRIANGLE_FAN, 0, 4);
      vbo.dispose();
      tex.dispose();
    } catch (_) {
      _drawImgPlaceholder(x, y, width, height);
    }
  }

  void _drawTexturedQuad(Texture tex, double w, double h,
      double px, double py, _GlesShared g, List<double> c) {
    final snapX = px.roundToDouble();
    final snapY = py.roundToDouble();
    final (l, t) = _toClip(snapX, snapY);
    final (r, b) = _toClip(snapX + w, snapY + h);
    final verts = Float32List(16);
    verts[0] = l;  verts[1] = b;  verts[2] = 0;  verts[3] = 1;
    verts[4] = r;  verts[5] = b;  verts[6] = 1;  verts[7] = 1;
    verts[8] = r;  verts[9] = t;  verts[10] = 1;  verts[11] = 0;
    verts[12] = l; verts[13] = t; verts[14] = 0;  verts[15] = 0;

    final vbo = VertexBuffer();
    vbo.setData(verts, usage: GL_STREAM_DRAW);
    vbo.bind();
    g.textProgram.use();
    g.gl.uniform4f(g.uTexColor, c[0], c[1], c[2], c[3]);
    g.gl.uniform1i(g.uTexture, 0);
    vbo.attribPointer(g.aTexPos, 2, GL_FLOAT, false, 16, 0);
    g.gl.enableVertexAttrib(g.aTexPos);
    vbo.attribPointer(g.aTexCoord, 2, GL_FLOAT, false, 16, 8);
    g.gl.enableVertexAttrib(g.aTexCoord);
    g.gl.activeTexture(0x84C0);
    tex.bind();
    _applyScissor();
    vbo.drawArrays(GL_TRIANGLE_FAN, 0, 4);
    vbo.dispose();
  }

  void _drawImgPlaceholder(double x, double y, double? w, double? h) {
    drawRect(Rect.fromLTWH(x, y, w ?? 16, h ?? 16),
        Paint()..color = const Color(0x60, 0x60, 0x70));
  }

  @override
  @override
  void clipRect(Rect rect) {
    // Apply current transform to clip rectangle.
    final (l, t) = _transform(rect.left, rect.top);
    final (r, b) = _transform(rect.right, rect.bottom);
    final xfRect = Rect.fromLTRB(l, t, r, b);

    final cur = _clips.last;
    if (cur == null) {
      _clips[_clips.length - 1] = xfRect;
    } else {
      _clips[_clips.length - 1] = Rect.fromLTRB(
        xfRect.left > cur.left ? xfRect.left : cur.left,
        xfRect.top > cur.top ? xfRect.top : cur.top,
        xfRect.right < cur.right ? xfRect.right : cur.right,
        xfRect.bottom < cur.bottom ? xfRect.bottom : cur.bottom,
      );
    }
  }

  @override
  void save() {
    _clips.add(_clips.last);
    _matrixStack.add(Float64List.fromList(_currentMatrix));
  }

  @override
  void restore() {
    if (_clips.length > 1) _clips.removeLast();
    if (_matrixStack.length > 1) {
      _matrixStack.removeLast();
      _currentMatrix = _matrixStack.last;
    }
  }

  @override
  void translate(double dx, double dy) {
    // Append translation: [1, 0, 0, 1, dx, dy] * current.
    final m = _currentMatrix;
    _currentMatrix = Float64List.fromList([
      m[0], m[1],
      m[2], m[3],
      m[0] * dx + m[2] * dy + m[4],
      m[1] * dx + m[3] * dy + m[5],
    ]);
  }

  @override
  void scale(double sx, double sy) {
    // Append scale: [sx, 0, 0, sy, 0, 0] * current.
    final m = _currentMatrix;
    _currentMatrix = Float64List.fromList([
      m[0] * sx, m[1] * sx,
      m[2] * sy, m[3] * sy,
      m[4], m[5],
    ]);
  }

  /// glReadPixels returns rows from bottom to top; Wayland SHM expects
  /// top to bottom.  Flip the raw RGBA rows before writing to the fd.
  Uint8List _flipFramebufferRows(Uint8List src) {
    const bpp = 4;
    final rowBytes = _width * bpp;
    final dst = Uint8List(src.length);
    for (var y = 0; y < _height; y++) {
      final srcRow = _height - 1 - y;
      dst.setRange(
        y * rowBytes,
        (y + 1) * rowBytes,
        src,
        srcRow * rowBytes,
      );
    }
    return dst;
  }

  @override
  void flush() {
    if (_failed || _disposed || _gles == null) return;
    try {
      final bottomUp = _gles!.gl.readPixelsAll();
      final topDown = _flipFramebufferRows(bottomUp);
      writeToFd(fd, topDown);
    } catch (e) {
      stderr.writeln('[wt:gles] flush error: $e');
    }
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _vbo?.dispose();
    _vbo = null;
  }
}


/// Cached rendered text texture.
class _TextCacheEntry {
  final Texture tex;
  final double width;
  final double height;
  _TextCacheEntry(this.tex, this.width, this.height);
}
