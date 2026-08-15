import 'dart:io' show stderr;

import 'app.dart';
import 'backend/backend.dart';
import 'debug.dart';
import 'mixins/event.dart';
import 'painter/painter.dart';
import 'palette.dart';
import 'renderer.dart';

mixin WindowBehavior on Backend, EventReceiver {
  /// Select which render backend to use. `null` reads the process environment
  /// and defaults to auto. See [RendererBackend.fromEnvironment].
  RendererBackend? rendererBackend;

  void initWindow() {
    Application.instance.addEventReceiver(this);
    onFrameReady = () => paint();
    onConfigure = (w, h) {
      width = w;
      height = h;
      onResize(w, h);
      paint();
    };
    onClose = () {
      Application.instance.quit();
    };
  }

  void paint() {
    if (toolkitDebugLogs) {
      stderr.writeln(
        '[wt] paint() called width=$width height=$height canPaint=$canPaint',
      );
    }
    if (!canPaint) {
      if (toolkitDebugLogs) {
        stderr.writeln('[wt] paint: canPaint=false, requesting deferred paint');
      }
      requestPaint();
      return;
    }
    // Skip paint until the compositor sends a configure with real dimensions.
    if (width <= 0 || height <= 0) {
      if (toolkitDebugLogs) {
        stderr.writeln('[wt] paint: skipping (width=$width height=$height)');
      }
      return;
    }
    final painter = createPainter(width, height);
    if (toolkitDebugLogs) stderr.writeln('[wt] paint: painter=$painter');
    try {
      painter.clear(Palette.current.forState(true, true).window);
      draw(painter);
      paintWithPainter(painter);
    } finally {
      painter.dispose();
    }
  }

  @override
  void onEvent(Event event) {
    if (event is KeyEvent) {
      if (event.isPressed) {
        onKeyPressed(event);
      } else {
        onKeyReleased(event);
      }
    } else if (event is MouseEnterEvent) {
      onMouseEnter(event);
    } else if (event is MouseLeaveEvent) {
      onMouseLeave(event);
    } else if (event is MouseMotionEvent) {
      onMouseMotion(event);
    } else if (event is MouseWheelEvent) {
      onMouseWheel(event);
    } else if (event is MouseButtonEvent) {
      if (event.isPressed) {
        onMouseButtonPressed(event);
      } else {
        onMouseButtonReleased(event);
      }
    }
  }

  void draw(Painter painter) {}

  void onResize(int width, int height) {}
  void onKeyPressed(KeyEvent event) {}
  void onKeyReleased(KeyEvent event) {}
  void onMouseEnter(MouseEnterEvent event) {}
  void onMouseLeave(MouseLeaveEvent event) {}
  void onMouseMotion(MouseMotionEvent event) {}
  void onMouseWheel(MouseWheelEvent event) {}
  void onMouseButtonPressed(MouseButtonEvent event) {}
  void onMouseButtonReleased(MouseButtonEvent event) {}

  Future<void> show() async {
    await init();
    start();
    Application.instance.addBackend(this);
  }
}
