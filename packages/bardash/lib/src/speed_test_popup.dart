/// A click-to-open speed-test panel for bardash.
///
/// Measures live link throughput for a short window and paints a large
/// [Speedometer] gauge with the result. Popup placement, input routing, and
/// presentation are provided by the toolkit's [LayerPopupHost].
library;

import 'dart:io';
import 'dart:math' show max;

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

/// Toolkit-owned content for the speed-test popup.
///
/// The surrounding overlay is responsible only for speed-test state and
/// placement; every visible control is a normal toolkit widget. This keeps
/// typography, spacing, hover transitions, focus, and button activation on
/// the same code path as the rest of Bardash.
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

  static bool get isOpen => _active != null;

  static void close() {
    _generation++;
    _active?.destroy();
    _active = null;
  }

  static Future<void> open({
    required LayerPopupHost popupHost,
    required int anchorX,
    required int parentWidth,
    required int parentHeight,
    required bool openUpward,
  }) async {
    _generation++;
    final gen = _generation;
    _active?.destroy();
    _active = null;

    late final SpeedTestOverlay overlay;
    overlay = SpeedTestOverlay(
      popupHost: popupHost,
      anchorX: anchorX,
      parentWidth: parentWidth,
      parentHeight: parentHeight,
      openUpward: openUpward,
      onClosed: () {
        if (identical(_active, overlay)) _active = null;
      },
    );
    _active = overlay;
    try {
      await overlay.show();
    } catch (e) {
      stderr.writeln('[speedtest] popup failed: $e');
      overlay.destroy();
      if (identical(_active, overlay)) _active = null;
    }
    if (identical(_active, overlay) && !overlay.isOpen) {
      _active = null;
    }
    if (gen != _generation) return;
  }
}

class SpeedTestOverlay {
  final LayerPopupHost popupHost;
  final int anchorX;
  final int parentWidth;
  final int parentHeight;
  final bool openUpward;
  final void Function()? onClosed;

  LayerPopup? _popup;

  late final SpeedTestView _view;
  late final AnimationController _needleAnimation;
  bool _open = false;
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
    required this.popupHost,
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
    final placement = BarPopupPlacement.forBar(
      anchorX: anchorX,
      parentWidth: parentWidth,
      width: _w,
      height: _h,
      openUpward: openUpward,
      keyboardMode: LayerKeyboardMode.onDemand,
    );
    final dismissPlacement = LayerSurfacePlacement(
      anchors: {
        LayerEdge.top,
        LayerEdge.right,
        LayerEdge.bottom,
        LayerEdge.left,
      },
      width: 0,
      height: 0,
      marginTop: openUpward ? 0 : parentHeight,
      marginBottom: openUpward ? parentHeight : 0,
      exclusiveZone: -1,
      keyboardMode: LayerKeyboardMode.none,
    );
    _popup = popupHost.create(
      content: _view,
      placement: placement,
      dismissPlacement: dismissPlacement,
      background: _bg,
      onEvent: _handlePopupEvent,
      onClosed: _onPopupClosed,
    );
    final shown = await _popup!.show();
    if (!shown) {
      _popup = null;
      return;
    }
    _open = true;
    stderr.writeln('[speedtest] open overlay $_w x $_h anchorX=$anchorX');
  }

  void hide() {
    if (!_open && _popup == null) return;
    _open = false;
    _popup?.close();
  }

  void destroy() => hide();

  bool _handlePopupEvent(LayerPopupEvent popupEvent) {
    final event = popupEvent.event;
    if (popupEvent.isOutside) {
      if (popupEvent.isOutsideClick) hide();
      return false;
    }
    // LayerPopup routes content through the shared widget host. This popup
    // only needs the outside-click policy above.
    return false;
  }

  void _onPopupClosed() {
    _open = false;
    _popup = null;
    _needleAnimation.stop();
    _needleAnimation.dispose();
    _view.dispose();
    onClosed?.call();
  }

  void _onNeedleFrame() {
    if (!_open) return;
    _refreshView();
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

  void _scheduleRepaint() {
    _popup?.requestRepaint();
  }
}
