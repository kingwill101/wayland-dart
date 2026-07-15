import 'package:test/test.dart';
import 'package:window_toolkit/window_toolkit.dart';

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

final class DrawImageCommand extends PaintCommand {
  final String filePath;
  final double x;
  final double y;
  final double? width;
  final double? height;
  DrawImageCommand(this.filePath, this.x, this.y, {this.width, this.height});
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
    required this.size,
    required this.fontFamily,
  });
}

final class RecordedPaint {
  final Color color;
  final PaintStyle style;
  final double strokeWidth;
  final bool antiAlias;

  const RecordedPaint({
    required this.color,
    required this.style,
    required this.strokeWidth,
    required this.antiAlias,
  });

  factory RecordedPaint.fromPaint(Paint paint) {
    return RecordedPaint(
      color: paint.color,
      style: paint.style,
      strokeWidth: paint.strokeWidth,
      antiAlias: paint.antiAlias,
    );
  }
}

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

  @override
  void clear(Color color) {
    commands.add(ClearCommand(color));
  }

  @override
  void drawRect(Rect rect, Paint paint) {
    commands.add(DrawRectCommand(_transformRect(rect), RecordedPaint.fromPaint(paint)));
  }

  @override
  void drawRRect(Rect rect, double radiusX, double radiusY, Paint paint) {
    // Record as rect for harness simplicity.
    commands.add(DrawRectCommand(_transformRect(rect), RecordedPaint.fromPaint(paint)));
  }

  @override
  void drawCircle(Offset center, double radius, Paint paint) {
    final transformedCenter = _transformOffset(center);
    final transformedRadius = radius * ((_current.sx + _current.sy) / 2);
    commands.add(DrawCircleCommand(
      transformedCenter,
      transformedRadius,
      RecordedPaint.fromPaint(paint),
    ));
  }

  @override
  void drawLine(Offset from, Offset to, Paint paint) {
    commands.add(DrawLineCommand(
      _transformOffset(from),
      _transformOffset(to),
      RecordedPaint.fromPaint(paint),
    ));
  }

  @override
  void drawText(String text, Offset position,
      {Color? color, double size = 14, String fontFamily = 'sans'}) {
    commands.add(DrawTextCommand(
      text,
      _transformOffset(position),
      color: color,
      size: size,
      fontFamily: fontFamily,
    ));
  }

  @override
  void drawImage(String filePath, double x, double y, {double? width, double? height}) {
    commands.add(DrawImageCommand(filePath, x, y, width: width, height: height));
  }

  @override
  Size measureText(String text, {double size = 14, String fontFamily = 'sans'}) {
    return Size(text.length * size * 0.5, size);
  }

  @override
  double measureTextAdvance(String text,
      {double size = 14, String fontFamily = 'sans'}) {
    return measureText(text, size: size, fontFamily: fontFamily).width;
  }

  @override
  Rect measureTextBounds(String text,
      {double size = 14, String fontFamily = 'sans'}) {
    final s = measureText(text, size: size, fontFamily: fontFamily);
    return Rect.fromLTWH(0, 0, s.width, s.height);
  }

  @override
  void save() {
    _stack.add(_current);
  }

  @override
  void restore() {
    if (_stack.length > 1) {
      _stack.removeLast();
    }
  }

  @override
  void translate(double dx, double dy) {
    _stack[_stack.length - 1] = _current.translate(dx, dy);
  }

  @override
  void scale(double sx, double sy) {
    _stack[_stack.length - 1] = _current.scale(sx, sy);
  }

  Rect _transformRect(Rect rect) {
    return Rect.fromLTRB(
      rect.left * _current.sx + _current.tx,
      rect.top * _current.sy + _current.ty,
      rect.right * _current.sx + _current.tx,
      rect.bottom * _current.sy + _current.ty,
    );
  }

  Offset _transformOffset(Offset offset) {
    return Offset(
      offset.dx * _current.sx + _current.tx,
      offset.dy * _current.sy + _current.ty,
    );
  }

  @override
  void clipRect(Rect rect) {
    commands.add(ClipRectCommand(_transformRect(rect)));
  }

  void clearCommands() => commands.clear();
}

final class WidgetHarness<T extends Widget> {
  final T widget;
  final RecordingPainter painter;

  WidgetHarness(
    this.widget, {
    RecordingPainter? painter,
  }) : painter = painter ?? RecordingPainter();

  T withBounds({
    int x = 0,
    int y = 0,
    int? width,
    int? height,
  }) {
    widget.x = x;
    widget.y = y;
    if (width != null) {
      widget.width = width;
    }
    if (height != null) {
      widget.height = height;
    }
    return widget;
  }

  List<PaintCommand> draw() {
    widget.draw(painter);
    return painter.commands;
  }

  bool hitTest(int x, int y) => widget.hitTest(x, y);

  void clear() => painter.clearCommands();
}

extension PaintCommandListX on List<PaintCommand> {
  Iterable<T> ofType<T extends PaintCommand>() => whereType<T>();

  T singleOfType<T extends PaintCommand>() {
    final matches = ofType<T>().toList();
    expect(matches, hasLength(1));
    return matches.single;
  }
}

final class _TransformState {
  final double tx;
  final double ty;
  final double sx;
  final double sy;

  const _TransformState(this.tx, this.ty, this.sx, this.sy);

  const _TransformState.identity()
      : tx = 0,
        ty = 0,
        sx = 1,
        sy = 1;

  _TransformState translate(double dx, double dy) {
    return _TransformState(tx + dx, ty + dy, sx, sy);
  }

  _TransformState scale(double scaleX, double scaleY) {
    return _TransformState(tx, ty, sx * scaleX, sy * scaleY);
  }
}
