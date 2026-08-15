import 'package:test/test.dart';
import 'package:window_toolkit/window_toolkit.dart';

abstract class FakeBackendBase implements Backend, EventReceiver {
  int _width = 0;
  int _height = 0;
  bool _running = false;
  void Function(int width, int height)? _onConfigure;
  Function()? _onClose;

  @override
  WaylandConnection get connection => Application.instance.connection;

  @override
  bool get canPaint => true;

  @override
  VoidCallback? onFrameReady;

  @override
  void requestPaint() {}

  @override
  bool get isRunning => _running;

  @override
  int get width => _width;

  @override
  set width(int value) {
    _width = value;
  }

  @override
  int get height => _height;

  @override
  set height(int value) {
    _height = value;
  }

  @override
  void Function(int width, int height)? get onConfigure => _onConfigure;

  @override
  set onConfigure(void Function(int width, int height)? callback) {
    _onConfigure = callback;
  }

  @override
  Function()? get onClose => _onClose;

  @override
  set onClose(Function()? callback) {
    _onClose = callback;
  }

  @override
  void dispatchEvents() {}

  @override
  void destroy() {}

  @override
  Future<void> init() async {}

  @override
  void start() {
    _running = true;
  }

  @override
  void onEvent(Event event) {}
}

class FakeWindow extends FakeBackendBase with WindowBehavior {
  int resizeCalls = 0;
  int paintCalls = 0;
  final List<String> log = [];

  FakeWindow() {
    initWindow();
  }

  @override
  Painter createPainter(int width, int height) {
    paintCalls++;
    return RecordingPainter(width: width.toDouble(), height: height.toDouble());
  }

  @override
  void paintWithPainter(Painter painter) {}

  @override
  void draw(Painter painter) {
    log.add('draw:${width}x$height');
  }

  @override
  void onResize(int width, int height) {
    resizeCalls++;
    log.add('resize:${width}x$height');
  }
}

void main() {
  setUp(() {
    Application.instance.reset();
  });

  tearDown(() {
    Application.instance.reset();
  });

  test('WindowBehavior notifies resize before painting', () {
    final window = FakeWindow();

    window.onConfigure?.call(320, 240);

    expect(window.width, 320);
    expect(window.height, 240);
    expect(window.resizeCalls, 1);
    expect(window.paintCalls, 1);
    expect(window.log, ['resize:320x240', 'draw:320x240']);
  });
}
