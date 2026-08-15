/// Recording [Painter] implementation for test verification.
///
/// Captures all draw calls as [PaintCommand] objects instead of
/// rendering.  Use with [TestHarness] or directly in widget tests.
library;

import '../drawing/color.dart';
import '../painter/painter.dart';

// ── Paint command types ──────────────────────────────────────────

sealed class PaintCommand {
  const PaintCommand();
}

final class ClearCommand extends PaintCommand {
  final Color color;
  const ClearCommand(this.color);
}

final class DrawRectCommand extends PaintCommand {
  final Rect rect;
  final RecordedPaint paint;
  const DrawRectCommand(this.rect, this.paint);
}

final class DrawCircleCommand extends PaintCommand {
  final Offset center;
  final double radius;
  final RecordedPaint paint;
  const DrawCircleCommand(this.center, this.radius, this.paint);
}

final class ClipRectCommand extends PaintCommand {
  final Rect rect;
  const ClipRectCommand(this.rect);
}

final class DrawLineCommand extends PaintCommand {
  final Offset from;
  final Offset to;
  final RecordedPaint paint;
  const DrawLineCommand(this.from, this.to, this.paint);
}

final class DrawArcCommand extends PaintCommand {
  final Rect oval;
  final double startAngle;
  final double sweepAngle;
  final bool useCenter;
  final RecordedPaint paint;
  const DrawArcCommand(
    this.oval,
    this.startAngle,
    this.sweepAngle,
    this.useCenter,
    this.paint,
  );
}

final class DrawImageCommand extends PaintCommand {
  final String filePath;
  final double x;
  final double y;
  final double? width;
  final double? height;
  DrawImageCommand(this.filePath, this.x, this.y, {this.width, this.height});
}

final class DrawLinearGradientCommand extends PaintCommand {
  final Rect rect;
  final Color color0;
  final Color color1;
  final double angle;
  const DrawLinearGradientCommand(
    this.rect,
    this.color0,
    this.color1,
    this.angle,
  );
}

final class DrawTextCommand extends PaintCommand {
  final String text;
  final Offset position;
  final Color? color;
  final double size;
  final String fontFamily;
  const DrawTextCommand(
    this.text,
    this.position, {
    this.color,
    this.size = 14,
    this.fontFamily = 'sans',
  });
}

// ── Recorded paint state ─────────────────────────────────────────

class RecordedPaint {
  final Color color;
  final PaintStyle style;
  final double strokeWidth;
  final bool antiAlias;

  const RecordedPaint({
    required this.color,
    this.style = PaintStyle.fill,
    this.strokeWidth = 1.0,
    this.antiAlias = true,
  });

  factory RecordedPaint.fromPaint(Paint p) => RecordedPaint(
    color: p.color,
    style: p.style,
    strokeWidth: p.strokeWidth,
    antiAlias: p.antiAlias,
  );
}

// ── Transform state ──────────────────────────────────────────────

class _TransformState {
  final double sx, sy, tx, ty;
  const _TransformState({this.sx = 1, this.sy = 1, this.tx = 0, this.ty = 0});
  static _TransformState identity() => const _TransformState();
}

// ── Recording painter ────────────────────────────────────────────

class RecordingPainter implements Painter {
  final double _width;
  final double _height;
  final List<PaintCommand> commands = [];
  final List<_TransformState> _stack = [_TransformState.identity()];

  RecordingPainter({double width = 800, double height = 600})
    : _width = width,
      _height = height;

  @override
  Size get size => Size(_width, _height);
  @override
  double get width => _width;
  @override
  double get height => _height;

  _TransformState get _current => _stack.last;

  Rect _transformRect(Rect r) {
    final t = _current;
    return Rect.fromLTRB(
      r.left * t.sx + t.tx,
      r.top * t.sy + t.ty,
      r.right * t.sx + t.tx,
      r.bottom * t.sy + t.ty,
    );
  }

  Offset _transformOffset(Offset o) {
    final t = _current;
    return Offset(o.dx * t.sx + t.tx, o.dy * t.sy + t.ty);
  }

  void clearCommands() => commands.clear();

  @override
  void clear(Color color) => commands.add(ClearCommand(color));

  @override
  void drawRect(Rect rect, Paint paint) => commands.add(
    DrawRectCommand(_transformRect(rect), RecordedPaint.fromPaint(paint)),
  );

  @override
  void drawRRect(Rect rect, double radiusX, double radiusY, Paint paint) =>
      commands.add(
        DrawRectCommand(_transformRect(rect), RecordedPaint.fromPaint(paint)),
      );

  @override
  void drawCircle(Offset center, double radius, Paint paint) {
    final tc = _transformOffset(center);
    final tr = radius * ((_current.sx + _current.sy) / 2);
    commands.add(DrawCircleCommand(tc, tr, RecordedPaint.fromPaint(paint)));
  }

  @override
  void drawLine(Offset from, Offset to, Paint paint) => commands.add(
    DrawLineCommand(
      _transformOffset(from),
      _transformOffset(to),
      RecordedPaint.fromPaint(paint),
    ),
  );

  @override
  void drawArc(
    Rect oval,
    double startAngle,
    double sweepAngle,
    bool useCenter,
    Paint paint,
  ) {
    commands.add(
      DrawArcCommand(
        _transformRect(oval),
        startAngle,
        sweepAngle,
        useCenter,
        RecordedPaint.fromPaint(paint),
      ),
    );
  }

  @override
  void drawText(
    String text,
    Offset position, {
    Color? color,
    double size = 14,
    String fontFamily = 'sans',
  }) {
    commands.add(
      DrawTextCommand(
        text,
        _transformOffset(position),
        color: color,
        size: size,
        fontFamily: fontFamily,
      ),
    );
  }

  @override
  Size measureText(
    String text, {
    double size = 14,
    String fontFamily = 'sans',
  }) => Size(text.length * size * 0.6, size);

  @override
  double measureTextAdvance(
    String text, {
    double size = 14,
    String fontFamily = 'sans',
  }) => text.length * size * 0.6;

  @override
  Rect measureTextBounds(
    String text, {
    double size = 14,
    String fontFamily = 'sans',
  }) => Rect.fromLTWH(0, 0, text.length * size * 0.6, size);

  @override
  void drawImage(
    String filePath,
    double x,
    double y, {
    double? width,
    double? height,
  }) {
    commands.add(
      DrawImageCommand(
        filePath,
        _current.tx + x,
        _current.ty + y,
        width: width,
        height: height,
      ),
    );
  }

  @override
  void flush() {}

  @override
  void dispose() {}

  @override
  void drawLinearGradient(
    Rect rect,
    Color color0,
    Color color1, {
    double angle = 0.0,
  }) {
    commands.add(
      DrawLinearGradientCommand(_transformRect(rect), color0, color1, angle),
    );
  }

  @override
  void clipRect(Rect rect) =>
      commands.add(ClipRectCommand(_transformRect(rect)));

  @override
  void save() => _stack.add(
    _TransformState(
      sx: _current.sx,
      sy: _current.sy,
      tx: _current.tx,
      ty: _current.ty,
    ),
  );

  @override
  void restore() {
    if (_stack.length > 1) _stack.removeLast();
  }

  @override
  void translate(double dx, double dy) {
    _stack[_stack.length - 1] = _TransformState(
      sx: _current.sx,
      sy: _current.sy,
      tx: _current.tx + dx,
      ty: _current.ty + dy,
    );
  }

  @override
  void scale(double sx, double sy) {
    _stack[_stack.length - 1] = _TransformState(
      sx: _current.sx * sx,
      sy: _current.sy * sy,
      tx: _current.tx,
      ty: _current.ty,
    );
  }
}

/// Extension on [List<PaintCommand>] for convenient test assertions.
extension PaintCommandListX on List<PaintCommand> {
  /// All commands of type [T].
  Iterable<T> ofType<T extends PaintCommand>() => whereType<T>();

  /// The single command of type [T], or throws.
  T singleOfType<T extends PaintCommand>() {
    final matches = ofType<T>().toList();
    if (matches.length != 1) {
      throw StateError(
        'Expected exactly one ${T.runtimeType}, got ${matches.length}',
      );
    }
    return matches.single;
  }
}
