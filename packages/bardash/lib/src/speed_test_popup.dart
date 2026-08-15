/// A click-to-open speed-test panel for bardash.
///
/// Measures live link throughput for a short window and paints a large
/// [Speedometer] gauge with the result. Surface plumbing mirrors the
/// network/audio popups (layer overlay + dismiss catcher).
library;

import 'dart:async' as dart_async;
import 'dart:io';
import 'dart:math' show max;

import 'package:wayland/wayland.dart';
import 'package:window_toolkit/window_toolkit.dart';

import 'speedtest_service.dart';

/// Pure layout for the speed-test panel.
class SpeedPanelLayout {
  final int width;
  final int height;

  SpeedPanelLayout({int? width, int? height})
    : width = width ?? 420,
      height = height ?? 420;

  static const pad = 20;
  static const gaugeH = 250;
  static const btnH = 38;

  int get gaugeY => pad + 28;
  int get statusY => gaugeY + gaugeH + 12;
  int get btnY => height - pad - btnH;
  int get btnW => ((width - pad * 3) / 2).round();

  Rect btnStart() => Rect.fromLTWH(
    pad.toDouble(),
    btnY.toDouble(),
    btnW.toDouble(),
    btnH.toDouble(),
  );

  Rect btnClose() => Rect.fromLTWH(
    (pad + btnW + pad).toDouble(),
    btnY.toDouble(),
    btnW.toDouble(),
    btnH.toDouble(),
  );

  bool _inRect(Rect b, double x, double y) =>
      x >= b.left && x <= b.right && y >= b.top && y <= b.bottom;

  bool hitStart(double x, double y) => _inRect(btnStart(), x, y);
  bool hitClose(double x, double y) => _inRect(btnClose(), x, y);
}

/// Toolkit-owned content for the speed-test surface.
///
/// The overlay below is still responsible for the Wayland layer and SHM
/// buffers, but every visible control is a normal toolkit widget. This keeps
/// typography, spacing, hover transitions, focus, and button activation on
/// the same code path as the rest of bardash.
class SpeedTestView extends Widget {
  final VoidCallback onStart;
  final VoidCallback onClose;

  late final Label title;
  late final Chip phase;
  late final Chip download;
  late final Chip upload;
  late final Speedometer gauge;
  late final Label status;
  late final Label summary;
  late final Button startButton;
  late final Button closeButton;
  late final Card card;
  late final DecoratedBox shell;

  SpeedTestView({required this.onStart, required this.onClose}) {
    title = Label(
      'Speed Test',
      color: const Color(244, 242, 246),
      fontSize: 17,
    );
    phase = Chip(
      label: 'READY',
      backgroundColor: const Color(65, 57, 62),
      textColor: const Color(210, 202, 213),
      paddingH: 9,
      paddingV: 3,
      fontSize: 10,
    );
    download = Chip(
      label: '↓ 0.0 Mbps',
      backgroundColor: const Color(35, 71, 70),
      textColor: const Color(130, 239, 212),
      paddingH: 10,
      paddingV: 4,
      fontSize: 12,
    );
    upload = Chip(
      label: '↑ — Mbps',
      backgroundColor: const Color(58, 45, 75),
      textColor: const Color(200, 164, 255),
      paddingH: 10,
      paddingV: 4,
      fontSize: 12,
    );
    gauge = Speedometer(
      valueText: '0.0 Mbps',
      maxValue: 100,
      fillColor: const Color(105, 236, 195),
      textColor: const Color(244, 242, 246),
    );
    status = Label(
      'Ready when you are',
      color: const Color(170, 162, 173),
      fontSize: 12,
      maxWidth: 360,
    );
    summary = Label(
      'Measures download and upload throughput',
      color: const Color(125, 118, 129),
      fontSize: 11,
      maxWidth: 360,
    );
    startButton = Button(
      'Start Test',
      textColor: const Color(248, 246, 250),
      backgroundColor: const Color(78, 86, 104),
      hoverColor: const Color(103, 114, 137),
      padding: 10,
      charHeight: 13,
      onPressed: onStart,
    );
    closeButton = Button(
      'Close',
      textColor: const Color(248, 246, 250),
      backgroundColor: const Color(61, 57, 64),
      hoverColor: const Color(86, 80, 90),
      padding: 10,
      charHeight: 13,
      onPressed: onClose,
    );

    final header = HBox(spacing: 8, children: [title, phase]);
    final stats = HBox(spacing: 8, children: [download, upload]);
    final actions = HBox(
      spacing: 12,
      children: [
        SizedBox(width: 174, height: 38, child: startButton),
        SizedBox(width: 174, height: 38, child: closeButton),
      ],
    );
    card = Card(
      children: [header, stats, gauge, status, summary, actions],
      backgroundColor: const Color(0, 0, 0, 0),
      borderWidth: 0,
      padding: 18,
      spacing: 8,
    );
    shell = DecoratedBox(
      color: const Color(30, 27, 30),
      borderColor: const Color(105, 92, 105),
      borderWidth: 1,
      borderRadius: 15,
      child: card,
    );

    // This surface is hosted by the existing layer overlay rather than a
    // WidgetWindow, so initialise interactive primitives explicitly.
    startButton.initState();
    closeButton.initState();
  }

  List<Button> get buttons => [startButton, closeButton];

  @override
  List<Widget> get children => [shell];

  @override
  void measure(Painter painter) {
    title.measure(painter);
    phase.measure(painter);
    download.measure(painter);
    upload.measure(painter);
    gauge.measure(painter);
    status.measure(painter);
    summary.measure(painter);
    startButton.measure(painter);
    closeButton.measure(painter);
  }

  @override
  void performLayout(int containerWidth) {
    width = containerWidth;
    shell
      ..x = x
      ..y = y
      ..performLayout(containerWidth);
    height = shell.height;
  }

  @override
  void draw(Painter canvas) {
    shell
      ..x = x
      ..y = y
      ..width = width
      ..height = height;
    shell.draw(canvas);
  }

  @override
  bool hitTest(int px, int py) => shell.hitTest(px, py);

  Button? buttonAt(int px, int py) {
    for (final button in buttons.reversed) {
      if (button.hitTest(px, py)) return button;
    }
    return null;
  }

  void update({
    required String phaseName,
    required String statusText,
    required String summaryText,
    required double gaugeValue,
    required double maxValue,
    required String valueText,
    required bool failed,
  }) {
    final upper = phaseName == 'idle'
        ? 'READY'
        : phaseName == 'done'
        ? (failed ? 'FAILED' : 'COMPLETE')
        : phaseName.toUpperCase();
    phase
      ..label = upper
      ..backgroundColor = failed
          ? const Color(83, 52, 47)
          : phaseName == 'done'
          ? const Color(38, 78, 64)
          : const Color(65, 57, 62)
      ..textColor = failed
          ? const Color(255, 188, 157)
          : phaseName == 'done'
          ? const Color(139, 241, 190)
          : const Color(210, 202, 213);
    download.label = '↓ ${_formatRate(_downloadValue)}';
    upload.label = '↑ ${_formatRate(_uploadValue)}';
    status.text = statusText;
    summary.text = summaryText;
    gauge
      ..value = gaugeValue
      ..maxValue = maxValue
      ..valueText = valueText
      ..label = phaseName == 'download'
          ? 'Download'
          : phaseName == 'upload'
          ? 'Upload'
          : phaseName == 'done'
          ? 'Result'
          : ''
      ..fillColor = phaseName == 'upload'
          ? const Color(190, 139, 255)
          : const Color(105, 236, 195);
    startButton.text = phaseName == 'idle'
        ? 'Start Test'
        : phaseName == 'done'
        ? 'Run Again'
        : 'Testing…';
  }

  double _downloadValue = 0;
  double _uploadValue = 0;

  void setRates(double down, double up) {
    _downloadValue = down;
    _uploadValue = up;
  }

  String _formatRate(double value) =>
      value <= 0 ? '— Mbps' : '${value.toStringAsFixed(1)} Mbps';

  @override
  void dispose() {
    startButton.dispose();
    closeButton.dispose();
    super.dispose();
  }
}

class SpeedTestController {
  static SpeedTestOverlay? _active;
  static int _generation = 0;

  static bool get isOpen => _active?.isOpen ?? false;

  static void close() {
    _generation++;
    _active?.destroy();
    _active = null;
  }

  static Future<void> open({
    required WaylandConnection connection,
    required int anchorX,
    required int parentWidth,
    required int parentHeight,
    required bool openUpward,
  }) async {
    _generation++;
    final gen = _generation;
    _active?.destroy();
    _active = null;

    if (connection.layerShell == null) {
      stderr.writeln('[speedtest] layer shell not available');
      return;
    }

    late final SpeedTestOverlay overlay;
    overlay = SpeedTestOverlay(
      connection: connection,
      anchorX: anchorX,
      parentWidth: parentWidth,
      parentHeight: parentHeight,
      openUpward: openUpward,
      onClosed: () {
        if (identical(_active, overlay)) _active = null;
      },
    );
    _active = overlay;
    await overlay.show();
    if (gen != _generation) return;
  }
}

class SpeedTestOverlay with EventReceiver {
  final WaylandConnection connection;
  final int anchorX;
  final int parentWidth;
  final int parentHeight;
  final bool openUpward;
  final void Function()? onClosed;

  WlSurface? _surface;
  LayerSurfaceV1? _layer;
  final List<WlShmPool?> _pools = [null, null];
  final List<WlBuffer?> _buffers = [null, null];
  final List<int> _fds = [-1, -1];
  final List<bool> _busy = [false, false];
  int _front = 0;
  bool _needsPaint = false;
  bool _paintScheduled = false;
  bool _presenting = false;

  WlSurface? _dismissSurface;
  LayerSurfaceV1? _dismissLayer;
  WlBuffer? _dismissBuffer;
  WlShmPool? _dismissPool;
  int _dismissFd = -1;
  int _dismissW = 0;
  int _dismissH = 0;

  late final SpeedTestView _view;
  late final AnimationController _needleAnimation;
  bool _open = false;
  int _openedAtMs = 0;
  double _needleStart = 0;

  // Sizes.
  static const _w = 420;
  static const _h = 420;

  // Colors.
  static const _bg = Color(30, 27, 30);

  // Test state.
  String _phase = 'idle'; // idle | download | upload | done
  double _downloadMax = 0;
  double _uploadMax = 0;
  double _liveValue = 0;
  double _needleTarget = 0;
  String _status = 'Ready';
  bool _completedWithError = false;

  String _fmtMbps(double v) => '${v.toStringAsFixed(1)} Mbps';

  double get _needleValue =>
      _needleStart + (_needleTarget - _needleStart) * _needleAnimation.value;

  void _setNeedleTarget(double value) {
    final double target = value.isFinite && value >= 0 ? value : 0.0;
    _needleStart = _needleValue;
    _needleTarget = target;
    _needleAnimation.reset();
    _needleAnimation.animateTo(1);
  }

  SpeedTestOverlay({
    required this.connection,
    required this.anchorX,
    this.parentWidth = 1920,
    this.parentHeight = 30,
    this.openUpward = true,
    this.onClosed,
  }) {
    _needleAnimation = AnimationController(
      duration: const Duration(milliseconds: 520),
      curve: easeOut,
    )..addListener(_onNeedleFrame);
    _view = SpeedTestView(onStart: _startTest, onClose: hide);
    _refreshView();
  }

  bool get isOpen => _open;

  Future<void> show() async {
    final shell = connection.layerShell!;
    if (!_createDismiss(shell)) {
      stderr.writeln('[speedtest] dismiss create failed');
      destroy();
      return;
    }
    if (!_createLayer(shell)) {
      stderr.writeln('[speedtest] layer create failed');
      destroy();
      return;
    }

    _dismissSurface!.commit();
    _surface!.commit();
    final ok = await _waitConfigureAsync();
    if (!ok) {
      stderr.writeln('[speedtest] configure timeout');
      destroy();
      return;
    }

    _mapDismiss();
    _mapLayer();

    _open = true;
    _openedAtMs = DateTime.now().millisecondsSinceEpoch;
    Application.instance.removeEventReceiver(this);
    Application.instance.prependEventReceiver(this);

    stderr.writeln('[speedtest] open overlay $_w x $_h anchorX=$anchorX');
  }

  void hide() {
    if (!_open && _surface == null && _dismissSurface == null) return;
    _open = false;
    Application.instance.removeEventReceiver(this);
    _teardown();
    onClosed?.call();
  }

  void destroy() => hide();

  @override
  void onEvent(Event event) {
    if (!_open) return;

    final surf = connection.pointerSurfaceId;
    final onLayer = surf != null && surf == _surface?.objectId;
    final onDismiss = surf != null && surf == _dismissSurface?.objectId;
    final age = DateTime.now().millisecondsSinceEpoch - _openedAtMs;

    if (age < 200) {
      if (onLayer || onDismiss) event.accept();
      return;
    }

    if (event is KeyEvent && event.isPressed) {
      if (event.key == 1 || event.character == '\x1b') {
        hide();
        event.accept();
      }
      return;
    }

    if (onDismiss) {
      if (event is MouseButtonEvent && event.isPressed) {
        // Dismiss on the outside click, but leave the event unaccepted so the
        // bar can process a click in its own strip immediately.
        hide();
      } else {
        event.accept();
      }
      return;
    }

    if (onLayer) {
      if (event is MouseEnterEvent ||
          event is MouseLeaveEvent ||
          event is MouseMotionEvent) {
        final mx = event is MouseEnterEvent
            ? event.x
            : event is MouseLeaveEvent
            ? event.x
            : (event as MouseMotionEvent).x;
        final my = event is MouseEnterEvent
            ? event.y
            : event is MouseLeaveEvent
            ? event.y
            : (event as MouseMotionEvent).y;
        _updateButtonHover(mx.round(), my.round());
        event.accept();
        return;
      }
      if (event is MouseButtonEvent) {
        final x = event.x;
        final y = event.y;
        if (event.isPressed) {
          _updateButtonHover(x.round(), y.round());
          final button = _view.buttonAt(x.round(), y.round());
          if (button != null) {
            _pressedButton = button;
            button.setInteractionState(WidgetState.pressed, true);
          }
        } else {
          final button = _pressedButton;
          if (button != null) {
            button.setInteractionState(WidgetState.pressed, false);
            if (identical(button, _view.buttonAt(x.round(), y.round()))) {
              button.activate();
            }
          }
          _pressedButton = null;
        }
        event.accept();
        return;
      }
      return;
    }

    if (event is MouseButtonEvent && event.isPressed) hide();
  }

  Button? _pressedButton;

  void _onNeedleFrame() {
    if (!_open) return;
    _refreshView();
    _scheduleRepaint();
  }

  void _updateButtonHover(int x, int y) {
    for (final button in _view.buttons) {
      button.setHovering(button.hitTest(x, y));
    }
    _scheduleRepaint();
  }

  Future<void> _startTest() async {
    if (_phase == 'download' || _phase == 'upload') return;
    _phase = 'download';
    _downloadMax = 0;
    _uploadMax = 0;
    _liveValue = 0;
    _needleStart = 0;
    _needleTarget = 0;
    _needleAnimation.reset();
    _completedWithError = false;
    _status = 'Measuring download…';
    _refreshView();
    _scheduleRepaint();

    try {
      final result = await SpeedTestEngine.run(
        onPhase: (phase) {
          if (!_open) return;
          _phase = phase;
          _status = phase == 'download'
              ? 'Measuring download…'
              : 'Measuring upload…';
          _refreshView();
          _scheduleRepaint();
        },
        onLive: (mbps) {
          if (!_open) return;
          _liveValue = mbps;
          _setNeedleTarget(mbps);
          if (_phase == 'upload') {
            if (_liveValue > _uploadMax) _uploadMax = _liveValue;
          } else if (_liveValue > _downloadMax) {
            _downloadMax = _liveValue;
          }
          _refreshView();
          _scheduleRepaint();
        },
      );
      if (!_open) return;
      _downloadMax = result.downloadMbps;
      _uploadMax = result.uploadMbps;
      _phase = 'done';
      _liveValue = _downloadMax;
      _setNeedleTarget(_downloadMax);
      _completedWithError = result.hasError;
      _status = result.hasError
          ? 'Error: ${result.error}'
          : 'Download ${_fmtMbps(_downloadMax)} · Upload ${_fmtMbps(_uploadMax)}';
      _refreshView();
    } on Exception catch (e) {
      if (!_open) return;
      _phase = 'done';
      _completedWithError = true;
      _status = 'Error: $e';
      _refreshView();
    }
    _scheduleRepaint();
  }

  double _displayScale() {
    final peak = max(100.0, max(_liveValue, max(_downloadMax, _uploadMax)));
    if (peak <= 100) return 100;
    if (peak <= 250) return 250;
    if (peak <= 500) return 500;
    if (peak <= 1000) return 1000;
    return (peak / 500).ceil() * 500;
  }

  void _refreshView() {
    final scale = _displayScale();
    final label = _phase == 'download'
        ? 'Download'
        : _phase == 'upload'
        ? 'Upload'
        : _phase == 'done'
        ? 'Final result'
        : 'Ready';
    final summary = _phase == 'idle'
        ? 'Measures download and upload throughput'
        : _phase == 'done' && !_completedWithError
        ? 'Download ${_fmtMbps(_downloadMax)}  ·  Upload ${_fmtMbps(_uploadMax)}'
        : _phase == 'done'
        ? 'Check your connection and try again'
        : 'Live measurement · ${label.toLowerCase()}';
    _view
      ..setRates(_downloadMax, _uploadMax)
      ..update(
        phaseName: _phase,
        statusText: _status,
        summaryText: summary,
        gaugeValue: (_needleValue / scale).clamp(0.0, 1.0),
        maxValue: scale,
        valueText: '${_needleValue.toStringAsFixed(1)} Mbps',
        failed: _completedWithError,
      );
  }

  // ── Layer surface setup ────────────────────────────────────────

  bool _createLayer(LayerShellV1 shell) {
    _surface = connection.compositor.createSurface().getOrElse((e) {
      stderr.writeln('[speedtest] surface: $e');
      return WlSurface(connection.context);
    });
    _layer = shell
        .getLayerSurface(
          _surface!,
          connection.output,
          LayerShellV1Layer.overlay.enumValue,
          'bardash-speedtest',
        )
        .getOrElse((e) {
          stderr.writeln('[speedtest] layer: $e');
          return LayerSurfaceV1(connection.context);
        });

    final menuX = (anchorX - 8).clamp(4, parentWidth - _w - 4);
    final preferRight = menuX + _w / 2 > parentWidth / 2;

    if (openUpward) {
      final bottom = parentHeight + 4;
      if (preferRight) {
        final right = (parentWidth - menuX - _w).clamp(0, parentWidth);
        _layer!.setAnchor(
          LayerSurfaceV1Anchor.bottom.enumValue |
              LayerSurfaceV1Anchor.right.enumValue,
        );
        _layer!.setMargin(0, right, bottom, 0);
      } else {
        _layer!.setAnchor(
          LayerSurfaceV1Anchor.bottom.enumValue |
              LayerSurfaceV1Anchor.left.enumValue,
        );
        _layer!.setMargin(0, 0, bottom, menuX);
      }
    } else {
      final top = parentHeight + 4;
      if (preferRight) {
        final right = (parentWidth - menuX - _w).clamp(0, parentWidth);
        _layer!.setAnchor(
          LayerSurfaceV1Anchor.top.enumValue |
              LayerSurfaceV1Anchor.right.enumValue,
        );
        _layer!.setMargin(top, right, 0, 0);
      } else {
        _layer!.setAnchor(
          LayerSurfaceV1Anchor.top.enumValue |
              LayerSurfaceV1Anchor.left.enumValue,
        );
        _layer!.setMargin(top, 0, 0, menuX);
      }
    }

    _layer!.setSize(_w, _h);
    _layer!.setExclusiveZone(0);
    // This is a transient popup, not a desktop-wide layer. On-demand focus
    // keeps it usable without stealing keyboard focus from unrelated apps.
    _layer!.setKeyboardInteractivity(
      LayerSurfaceV1KeyboardInteractivity.onDemand.enumValue,
    );
    _layer!.onConfigure((e) => _layer!.ackConfigure(e.serial));
    _layer!.onClosed((_) => hide());
    return true;
  }

  bool _createDismiss(LayerShellV1 shell) {
    _dismissSurface = connection.compositor.createSurface().getOrElse((e) {
      stderr.writeln('[speedtest] dismiss surface: $e');
      return WlSurface(connection.context);
    });
    _dismissLayer = shell
        .getLayerSurface(
          _dismissSurface!,
          connection.output,
          LayerShellV1Layer.overlay.enumValue,
          'bardash-speedtest-dismiss',
        )
        .getOrElse((e) {
          stderr.writeln('[speedtest] dismiss layer: $e');
          return LayerSurfaceV1(connection.context);
        });

    _dismissLayer!.setAnchor(
      LayerSurfaceV1Anchor.top.enumValue |
          LayerSurfaceV1Anchor.bottom.enumValue |
          LayerSurfaceV1Anchor.left.enumValue |
          LayerSurfaceV1Anchor.right.enumValue,
    );
    if (openUpward) {
      _dismissLayer!.setMargin(0, 0, parentHeight, 0);
    } else {
      _dismissLayer!.setMargin(parentHeight, 0, 0, 0);
    }
    _dismissLayer!.setSize(0, 0);
    _dismissLayer!.setExclusiveZone(-1);
    _dismissLayer!.setKeyboardInteractivity(
      LayerSurfaceV1KeyboardInteractivity.none.enumValue,
    );

    // Keep the surface as a transparent overlay anchor, but do not let it
    // claim pointer input across the output. The platform-specific region
    // setup belongs to the toolkit, not to this popup.
    SurfaceInputController(
      connection,
    ).setMode(_dismissSurface!, SurfaceInputMode.passthrough);

    _dismissLayer!.onConfigure((e) {
      _dismissLayer!.ackConfigure(e.serial);
      if (e.width > 0 && e.height > 0) {
        _dismissW = e.width;
        _dismissH = e.height;
      }
    });
    _dismissLayer!.onClosed((_) {});
    return true;
  }

  Future<bool> _waitConfigureAsync() async {
    final done = dart_async.Completer<void>();
    var sawLayer = false;
    var sawDismiss = false;
    void tryComplete() {
      if (sawLayer && sawDismiss && !done.isCompleted) done.complete();
    }

    _layer!.onConfigure((e) {
      _layer!.ackConfigure(e.serial);
      sawLayer = true;
      tryComplete();
    });
    _dismissLayer!.onConfigure((e) {
      _dismissLayer!.ackConfigure(e.serial);
      if (e.width > 0 && e.height > 0) {
        _dismissW = e.width;
        _dismissH = e.height;
      } else {
        _dismissW = parentWidth.clamp(1, 7680);
        _dismissH = 1440;
      }
      sawDismiss = true;
      tryComplete();
    });

    try {
      await done.future.timeout(const Duration(milliseconds: 500));
      return true;
    } on dart_async.TimeoutException {
      return false;
    }
  }

  void _mapLayer() {
    final stride = _w * 4;
    final slotSize = stride * _h;
    for (var i = 0; i < 2; i++) {
      final fd = createAnonymousFile(slotSize);
      if (fd < 0) return;
      _fds[i] = fd;
      final pool = connection.shm.createPool(fd, slotSize).getOrElse((e) {
        stderr.writeln('[speedtest] pool $i: $e');
        return WlShmPool(connection.context);
      });
      _pools[i] = pool;
      final buf = pool.createBuffer(0, _w, _h, stride, 0).getOrElse((e) {
        stderr.writeln('[speedtest] buffer $i: $e');
        return WlBuffer(connection.context);
      });
      final slot = i;
      buf.onRelease((_) {
        _busy[slot] = false;
        if (_needsPaint && _open) _scheduleRepaint();
      });
      _buffers[i] = buf;
      _busy[i] = false;
    }
    _front = 0;
    _needsPaint = false;
    _paintScheduled = false;
    _presenting = false;
    _present();
  }

  void _mapDismiss() {
    var w = _dismissW;
    var h = _dismissH;
    if (w <= 0 || h <= 0) {
      w = parentWidth.clamp(1, 7680);
      h = 1440;
      _dismissW = w;
      _dismissH = h;
    }
    final stride = w * 4;
    final size = stride * h;
    _dismissFd = createAnonymousFile(size);
    if (_dismissFd < 0) return;
    _dismissPool = connection.shm.createPool(_dismissFd, size).getOrElse((e) {
      stderr.writeln('[speedtest] dismiss pool: $e');
      return WlShmPool(connection.context);
    });
    _dismissBuffer = _dismissPool!.createBuffer(0, w, h, stride, 0).getOrElse((
      e,
    ) {
      stderr.writeln('[speedtest] dismiss buffer: $e');
      return WlBuffer(connection.context);
    });
    final painter = SkiaPainter(_dismissFd, w, h);
    try {
      painter.clear(const Color(0, 0, 0, 0));
      painter.flush();
    } finally {
      painter.dispose();
    }
    _dismissSurface!.attach(_dismissBuffer!, 0, 0);
    _dismissSurface!.damage(0, 0, w, h);
    _dismissSurface!.commit();
  }

  void _scheduleRepaint() {
    _needsPaint = true;
    if (_paintScheduled) return;
    _paintScheduled = true;
    dart_async.scheduleMicrotask(() {
      _paintScheduled = false;
      if (!_open || !_needsPaint) return;
      _present();
    });
  }

  void _present() {
    if (_surface == null || _presenting) {
      _needsPaint = true;
      return;
    }
    _presenting = true;
    try {
      var slot = 1 - _front;
      if (_busy[slot] || _buffers[slot] == null) slot = _front;
      if (_busy[slot] || _buffers[slot] == null || _fds[slot] < 0) {
        _needsPaint = true;
        return;
      }
      _paintInto(_fds[slot]);
      _busy[slot] = true;
      _front = slot;
      _needsPaint = false;
      _surface!.attach(_buffers[slot]!, 0, 0);
      _surface!.damage(0, 0, _w, _h);
      _surface!.commit();
    } finally {
      _presenting = false;
    }
  }

  void _paintInto(int fd) {
    if (fd < 0) return;
    final painter = SkiaPainter(fd, _w, _h);
    try {
      painter.clear(_bg);
      _view
        ..x = 0
        ..y = 0
        ..width = _w
        ..height = _h;
      _view.measure(painter);
      _view.performLayout(_w);
      _view.draw(painter);
      painter.flush();
    } finally {
      painter.dispose();
    }
  }

  void _teardown() {
    _needsPaint = false;
    _paintScheduled = false;
    _presenting = false;
    _phase = 'idle';
    _liveValue = 0;
    _pressedButton = null;
    _needleAnimation.stop();
    _view.dispose();
    _needleAnimation.dispose();
    for (var i = 0; i < 2; i++) {
      _buffers[i]?.destroy();
      _buffers[i] = null;
      _pools[i]?.destroy();
      _pools[i] = null;
      if (_fds[i] >= 0) {
        closeFd(_fds[i]);
        _fds[i] = -1;
      }
      _busy[i] = false;
    }
    _front = 0;
    _layer?.destroy();
    _layer = null;
    _surface?.destroy();
    _surface = null;

    _dismissBuffer?.destroy();
    _dismissBuffer = null;
    _dismissPool?.destroy();
    _dismissPool = null;
    if (_dismissFd >= 0) {
      closeFd(_dismissFd);
      _dismissFd = -1;
    }
    _dismissLayer?.destroy();
    _dismissLayer = null;
    _dismissSurface?.destroy();
    _dismissSurface = null;
    _dismissW = 0;
    _dismissH = 0;
  }
}
