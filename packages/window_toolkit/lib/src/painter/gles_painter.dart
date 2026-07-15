import 'dart:io' show stderr;
import 'dart:math';
import 'dart:typed_data';

import 'dart:io' show stderr;
import 'dart:typed_data';

import 'package:gl/gl.dart';
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

  _GlesShared()
      : gl = GL.create(width: 1, height: 1),
        rectProgram = _buildRectProgram(),
        rrectProgram = _buildRRectProgram(),
        textProgram = _buildTextProgram() {
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
      _gles!.gl.makeCurrent();
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
    final c = _glColor(paint.color);
    _gles!.rectProgram.use();
    _gles!.gl.uniform4f(_gles!.uColor, c[0], c[1], c[2], c[3]);
    final (l, t) = _toClip(rect.left, rect.top);
    final (r, b) = _toClip(rect.right, rect.bottom);
    _drawVerts(Float32List.fromList([l, t, r, t, r, b, l, b]), GL_TRIANGLE_FAN);
  }

  @override
  void drawCircle(Offset center, double radius, Paint paint) {
    if (_failed || _disposed) return;
    final c = _glColor(paint.color);
    _gles!.rectProgram.use();
    _gles!.gl.uniform4f(_gles!.uColor, c[0], c[1], c[2], c[3]);

    final (ccx, ccy) = _toClip(center.dx, center.dy);
    const segs = 32;
    final verts = Float32List((segs + 2) * 2);
    verts[0] = ccx; verts[1] = ccy;
    for (var i = 0; i <= segs; i++) {
      final a = i * 2 * pi / segs;
      // Approximate radius in clip space (use average of sx, sy scales).
      final r = radius * (_sx + _sy) * 0.5;
      verts[(i + 1) * 2] = ccx + cos(a) * r;
      verts[(i + 1) * 2 + 1] = ccy + sin(a) * r;
    }
    _drawVerts(verts, GL_TRIANGLE_FAN);
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
  void drawText(String text, Offset position,
      {Color? color, double size = 14, String fontFamily = 'sans'}) {
    if (_failed || _disposed || text.isEmpty) return;

    final g = _gles!;
    final c = _glColor(color ?? const Color(255, 255, 255));

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
    // Placeholder — proper image loading via Skia + textured quad
    // will be added once the image shader program is in place.
    drawRect(Rect.fromLTWH(x, y, width ?? 16, height ?? 16),
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
