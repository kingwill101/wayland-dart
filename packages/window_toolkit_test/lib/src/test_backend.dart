import 'dart:typed_data';

import 'package:window_toolkit/window_toolkit.dart';

/// A [Backend] that works without a Wayland compositor.
///
/// Uses [RecordingPainter] to capture paint commands for test
/// verification.
class TestBackend extends _TestBackendBase with EventReceiver, WindowBehavior {
  TestBackend({this.testWidth = 800, this.testHeight = 600});

  final int testWidth;
  final int testHeight;
  final _TestConnection _testConnection = _TestConnection();

  @override
  WaylandConnection get connection => _testConnection;

  @override
  int get width => _width;
  int _width = 800;
  @override
  set width(int v) => _width = v;

  @override
  int get height => _height;
  int _height = 600;
  @override
  set height(int v) => _height = v;

  @override
  bool _running = false;

  @override
  void Function(int width, int height)? onConfigure;
  @override
  Function()? onClose;
  @override
  VoidCallback? onFrameReady;

  late final RecordingPainter _painter = RecordingPainter(
      width: testWidth.toDouble(), height: testHeight.toDouble());

  /// The recorded paint commands from the last [paintWithPainter] call.
  List<PaintCommand> get commands => _painter.commands;

  /// Clear recorded commands.
  void clearCommands() => _painter.clearCommands();

  @override
  Future<void> init() async {
    _running = true;
    _width = testWidth;
    _height = testHeight;
  }

  @override
  void start() {}

  @override
  void dispatchEvents() {}

  @override
  void destroy() {
    _running = false;
  }

  @override
  bool get isRunning => _running;

  @override
  bool get canPaint => true;

  @override
  void requestPaint() {}

  @override
  Painter createPainter(int width, int height) {
    _painter.commands.clear();
    return _painter;
  }

  @override
  void paintWithPainter(Painter painter) {}
}

/// Base class implementing [Backend] for mixin compatibility.
class _TestBackendBase implements Backend {
  @override
  WaylandConnection get connection => throw UnimplementedError();

  @override
  int get width => 0;
  @override
  set width(int v) {}
  @override
  int get height => 0;
  @override
  set height(int v) {}

  @override
  void Function(int width, int height)? get onConfigure => null;
  @override
  set onConfigure(void Function(int width, int height)? callback) {}
  @override
  Function()? get onClose => null;
  @override
  set onClose(Function()? callback) {}

  @override
  bool get isRunning => false;
  @override
  bool get canPaint => true;
  @override
  void requestPaint() {}

  @override
  VoidCallback? onFrameReady;

  @override
  Future<void> init() async {}
  @override
  void start() {}
  @override
  void dispatchEvents() {}
  @override
  void destroy() {}

  @override
  Painter createPainter(int width, int height) =>
      RecordingPainter(width: width.toDouble(), height: height.toDouble());
  @override
  void paintWithPainter(Painter painter) {}
}

/// Fake connection that does nothing.
class _TestConnection extends WaylandConnection {
  @override
  bool get isConnected => false;
}
