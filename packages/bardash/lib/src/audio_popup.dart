/// A click-to-open audio panel (Windows-tray style) for bardash.
///
/// Clicking an audio module pops an overlay-layer panel with a master
/// volume slider + a mute toggle. Pointer drag on the slider drives
/// [PulseClient] (in-process), and the panel reflects live sink state.
///
/// Surface plumbing mirrors `tray_menu.dart` (the pattern proven there): a
/// dedicated `zwlr_layer_shell` overlay surface + a transparent full-output
/// dismiss catcher that closes on outside click. Geometry and hit-testing
/// are a pure, unit-testable [AudioPanelLayout].
library;

import 'dart:async' show scheduleMicrotask, Completer, TimeoutException;
import 'dart:io';

import 'package:wayland/wayland.dart';
import 'package:window_toolkit/window_toolkit.dart';

import 'native/pulse_client.dart';
import 'native/mpris_client.dart';

/// Pure layout + hit-testing for the audio panel. No Wayland, so it's
/// unit-testable headless.
class AudioPanelLayout {
  final int width;
  final int height;

  AudioPanelLayout({int? width, int? height})
    : width = width ?? 240,
      height = height ?? 200;

  static const pad = 12;
  static const sliderH = 8;
  static const thumbR = 7;

  // Sink (output) row.
  static const sliderY = 58;
  // Source (mic) row.
  static const sourceSliderY = 106;
  // Bottom action row.
  static const actionH = 24;

  int get mediaY => height - 106;
  int get actionsY => height - 42;

  Rect mediaPrevious() =>
      Rect.fromLTWH((width / 2 - 76).toDouble(), mediaY.toDouble(), 44, 30);
  Rect mediaPlayPause() =>
      Rect.fromLTWH((width / 2 - 22).toDouble(), mediaY.toDouble(), 44, 30);
  Rect mediaNext() =>
      Rect.fromLTWH((width / 2 + 32).toDouble(), mediaY.toDouble(), 44, 30);

  int get sliderX => pad;
  int get sliderW => width - pad * 2;

  bool _inTrackBand(double y, int trackTop) =>
      y >= trackTop - 6 && y <= trackTop + sliderH + 8;

  Rect sliderTrack() => Rect.fromLTWH(
    sliderX.toDouble(),
    sliderY.toDouble(),
    sliderW.toDouble(),
    sliderH.toDouble(),
  );

  Rect sourceSliderTrack() => Rect.fromLTWH(
    sliderX.toDouble(),
    sourceSliderY.toDouble(),
    sliderW.toDouble(),
    sliderH.toDouble(),
  );

  Offset thumbCenter(double fraction) => Offset(
    sliderX + sliderW * fraction.clamp(0.0, 1.0),
    sliderY + sliderH / 2,
  );

  Offset sourceThumbCenter(double fraction) => Offset(
    sliderX + sliderW * fraction.clamp(0.0, 1.0),
    sourceSliderY + sliderH / 2,
  );

  Rect muteButton() => Rect.fromLTWH(
    pad.toDouble(),
    actionsY.toDouble(),
    52.0,
    actionH.toDouble(),
  );

  Rect micMuteButton() => Rect.fromLTWH(
    (pad + 60).toDouble(),
    actionsY.toDouble(),
    52.0,
    actionH.toDouble(),
  );

  Rect mixerButton() => Rect.fromLTWH(
    (pad + 120).toDouble(),
    actionsY.toDouble(),
    (width - pad - (pad + 120)).toDouble(),
    actionH.toDouble(),
  );

  bool hitSlider(double x, double y) =>
      _inTrackBand(y, sliderY) &&
      x >= sliderX - thumbR &&
      x <= sliderX + sliderW + thumbR;

  bool hitSourceSlider(double x, double y) =>
      _inTrackBand(y, sourceSliderY) &&
      x >= sliderX - thumbR &&
      x <= sliderX + sliderW + thumbR;

  bool _inRect(Rect b, double x, double y) =>
      x >= b.left && x <= b.right && y >= b.top && y <= b.bottom;

  bool hitMute(double x, double y) => _inRect(muteButton(), x, y);

  bool hitMicMute(double x, double y) => _inRect(micMuteButton(), x, y);

  bool hitMixer(double x, double y) => _inRect(mixerButton(), x, y);
  bool hitMediaPrevious(double x, double y) => _inRect(mediaPrevious(), x, y);
  bool hitMediaPlayPause(double x, double y) => _inRect(mediaPlayPause(), x, y);
  bool hitMediaNext(double x, double y) => _inRect(mediaNext(), x, y);

  /// Fraction (0..1) for an x inside the track.
  double fractionForX(double x) => ((x - sliderX) / sliderW).clamp(0.0, 1.0);
}

class AudioPopupController {
  static AudioPopupOverlay? _active;
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
    String? mixerCommand,
  }) async {
    _generation++;
    final gen = _generation;
    _active?.destroy();
    _active = null;

    if (connection.layerShell == null) {
      stderr.writeln('[audio] layer shell not available');
      return;
    }

    late final AudioPopupOverlay overlay;
    overlay = AudioPopupOverlay(
      connection: connection,
      anchorX: anchorX,
      parentWidth: parentWidth,
      parentHeight: parentHeight,
      openUpward: openUpward,
      mixerCommand: mixerCommand,
      onClosed: () {
        if (identical(_active, overlay)) _active = null;
      },
    );
    _active = overlay;
    await overlay.show();
    if (gen != _generation) return;
  }
}

/// The overlay-layer audio panel surface.
class AudioPopupOverlay with EventReceiver {
  final WaylandConnection connection;
  final int anchorX;
  final int parentWidth;
  final int parentHeight;
  final bool openUpward;
  final String? mixerCommand;
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

  late final AudioPanelLayout _layout;
  bool _open = false;
  bool _draggingSink = false;
  bool _draggingSource = false;
  double _value = 0.0; // 0..1 sink fraction
  bool _muted = false;
  double _micValue = 0.0; // 0..1 source fraction
  bool _micMuted = false;
  int _openedAtMs = 0;
  MprisSnapshot _media = MprisSnapshot.empty;
  void Function(MprisSnapshot)? _mediaListener;
  String _hoverControl = '';
  late final TransportButton _previousButton;
  late final TransportButton _playPauseButton;
  late final TransportButton _nextButton;

  final int _w = 300;
  final int _h = 292;

  // Opaque panel colors (alpha 255), matching tray-menu chrome.
  static const _bg = Color(32, 32, 36);
  static const _border = Color(90, 90, 100);
  static const _text = Color(240, 240, 245);
  static const _dim = Color(150, 150, 160);
  static const _track = Color(58, 74, 80);
  static const _fill = Color(127, 179, 213);
  static const _micFill = Color(0x9d, 0xc2, 0x8c);
  static const _thumb = Color(242, 242, 247);
  static const _mutedFill = Color(46, 93, 59);
  static const _micMutedFill = Color(0x8a, 0x5a, 0x2e);
  static const _btn = Color(70, 78, 90);
  static const _btnHover = Color(88, 100, 116);
  static const _sep = Color(70, 70, 80);

  AudioPopupOverlay({
    required this.connection,
    required this.anchorX,
    this.parentWidth = 1920,
    this.parentHeight = 30,
    this.openUpward = true,
    this.mixerCommand,
    this.onClosed,
  }) {
    _layout = AudioPanelLayout(width: _w, height: _h);
    final s = PulseClient.instance.last;
    _value = (s.sinkPercent / 100).clamp(0.0, 1.0);
    _muted = s.sinkMuted;
    _micValue = (s.sourcePercent / 100).clamp(0.0, 1.0);
    _micMuted = s.sourceMuted;
    _media = MprisClient.instance.last;
    _previousButton = TransportButton(TransportAction.previous);
    _playPauseButton = TransportButton(TransportAction.play);
    _nextButton = TransportButton(TransportAction.next);
    _previousButton.initState();
    _playPauseButton.initState();
    _nextButton.initState();
  }

  bool get isOpen => _open;

  Future<void> show() async {
    final shell = connection.layerShell!;

    if (!_createDismiss(shell)) {
      stderr.writeln('[audio] dismiss create failed');
      destroy();
      return;
    }
    if (!_createLayer(shell)) {
      stderr.writeln('[audio] layer create failed');
      destroy();
      return;
    }

    _dismissSurface!.commit();
    _surface!.commit();
    final ok = await _waitConfigureAsync();
    if (!ok) {
      stderr.writeln('[audio] configure timeout');
      destroy();
      return;
    }

    _mapDismiss();
    _mapLayer();

    // Live updates from the audio daemon.
    PulseClient.instance.addListener((s) {
      if (!_open) return;
      _value = (s.sinkPercent / 100).clamp(0.0, 1.0);
      _muted = s.sinkMuted;
      _micValue = (s.sourcePercent / 100).clamp(0.0, 1.0);
      _micMuted = s.sourceMuted;
      _scheduleRepaint();
    });
    _mediaListener = (s) {
      if (!_open) return;
      _media = s;
      _scheduleRepaint();
    };
    MprisClient.instance.addListener(_mediaListener!);

    _open = true;
    _openedAtMs = DateTime.now().millisecondsSinceEpoch;
    Application.instance.removeEventReceiver(this);
    Application.instance.prependEventReceiver(this);

    stderr.writeln('[audio] open overlay ${_w}x$_h anchorX=$anchorX');
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

    // Grace period after open so the click that opened us is ignored.
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

    if (event is MouseLeaveEvent) {
      _draggingSink = false;
      _draggingSource = false;
      _hoverControl = '';
      _updateTransportHover();
      _scheduleRepaint();
      return;
    }

    if (onDismiss) {
      if (event is MouseButtonEvent && event.isPressed) {
        hide();
      }
      event.accept();
      return;
    }

    if (onLayer) {
      if (event is MouseMotionEvent) {
        final next = _controlAt(event.x, event.y);
        if (next != _hoverControl) {
          _hoverControl = next;
          _updateTransportHover();
          _scheduleRepaint();
        }
        if (_draggingSink) {
          _value = _layout.fractionForX(event.x);
          _applyVolume();
        } else if (_draggingSource) {
          _micValue = _layout.fractionForX(event.x);
          _applySourceVolume();
        }
        event.accept();
        return;
      }
      if (event is MouseWheelEvent) {
        // Wheel turns the row under the cursor: mic row → source, else sink.
        final byMic = _layout.hitSourceSlider(event.x, event.y);
        final up = event.dy < 0;
        final step = up ? 5 : -5;
        if (byMic) {
          PulseClient.instance.stepSourceVolume(step);
        } else {
          PulseClient.instance.stepVolume(step);
        }
        event.accept();
        return;
      }
      if (event is MouseEnterEvent) {
        event.accept();
        return;
      }
      if (event is MouseButtonEvent) {
        if (event.isPressed) {
          final x = event.x;
          final y = event.y;
          if (_layout.hitSlider(x, y)) {
            _draggingSink = true;
            _draggingSource = false;
            _value = _layout.fractionForX(x);
            _applyVolume();
            _scheduleRepaint();
          } else if (_layout.hitSourceSlider(x, y)) {
            _draggingSource = true;
            _draggingSink = false;
            _micValue = _layout.fractionForX(x);
            _applySourceVolume();
            _scheduleRepaint();
          } else if (_layout.hitMute(x, y)) {
            PulseClient.instance.toggleMute();
            _scheduleRepaint();
          } else if (_layout.hitMicMute(x, y)) {
            PulseClient.instance.toggleSourceMute();
            _scheduleRepaint();
          } else if (_layout.hitMixer(x, y)) {
            _openMixer();
          } else if (_layout.hitMediaPrevious(x, y)) {
            MprisClient.instance.previous();
          } else if (_layout.hitMediaPlayPause(x, y)) {
            MprisClient.instance.playPause();
          } else if (_layout.hitMediaNext(x, y)) {
            MprisClient.instance.next();
          } else {
            hide();
          }
        } else {
          _draggingSink = false;
          _draggingSource = false;
        }
        event.accept();
        return;
      }
      return;
    }

    if (event is MouseButtonEvent && event.isPressed) {
      hide();
    }
  }

  String _controlAt(double x, double y) {
    if (_layout.hitMediaPrevious(x, y)) return 'previous';
    if (_layout.hitMediaPlayPause(x, y)) return 'play-pause';
    if (_layout.hitMediaNext(x, y)) return 'next';
    if (_layout.hitMute(x, y)) return 'mute';
    if (_layout.hitMicMute(x, y)) return 'mic-mute';
    if (_layout.hitMixer(x, y)) return 'mixer';
    if (_layout.hitSlider(x, y)) return 'output';
    if (_layout.hitSourceSlider(x, y)) return 'mic';
    return '';
  }

  void _applyVolume() {
    final current = PulseClient.instance.last.sinkPercent;
    final target = (_value * 100).round();
    final delta = target - current;
    if (delta != 0) PulseClient.instance.stepVolume(delta);
  }

  void _applySourceVolume() {
    final current = PulseClient.instance.last.sourcePercent;
    final target = (_micValue * 100).round();
    final delta = target - current;
    if (delta != 0) PulseClient.instance.stepSourceVolume(delta);
  }

  /// Launch an external mixer (pavucontrol / pwvucontrol / ...), preferring
  /// the configured command, else the first installed candidate.
  void _openMixer() {
    final cmd = _resolveMixer();
    if (cmd == null) {
      stderr.writeln('[audio] no mixer found (pavucontrol/pwvucontrol/helvum)');
      return;
    }
    stderr.writeln('[audio] opening mixer: $cmd');
    Process.run(cmd, const [], runInShell: false);
  }

  String? _resolveMixer() {
    if (mixerCommand != null && mixerCommand!.trim().isNotEmpty) {
      return mixerCommand!.trim();
    }
    const candidates = ['pavucontrol', 'pwvucontrol', 'helvum', 'qpwgraph'];
    for (final c in candidates) {
      final r = Process.runSync('which', [c], runInShell: false);
      if (r.exitCode == 0) return c;
    }
    return null;
  }

  // ── Layer surface setup ────────────────────────────────────────

  bool _createLayer(LayerShellV1 shell) {
    _surface = connection.compositor.createSurface().getOrElse((e) {
      stderr.writeln('[audio] surface: $e');
      return WlSurface(connection.context);
    });
    _layer = shell
        .getLayerSurface(
          _surface!,
          connection.output,
          LayerShellV1Layer.overlay.enumValue,
          'bardash-audio',
        )
        .getOrElse((e) {
          stderr.writeln('[audio] layer: $e');
          return LayerSurfaceV1(connection.context);
        });

    // Same placement math as the tray menu: the panel's left edge tracks
    // the clicked module (clamped so the panel never leaves the screen),
    // and the side margin is derived from that x rather than hardcoded.
    final menuX = (anchorX - 8).clamp(
      4,
      (parentWidth - _w - 4).clamp(0, parentWidth),
    );
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
    _layer!.setKeyboardInteractivity(
      LayerSurfaceV1KeyboardInteractivity.exclusive.enumValue,
    );
    _layer!.onConfigure((e) => _layer!.ackConfigure(e.serial));
    _layer!.onClosed((_) => hide());
    return true;
  }

  bool _createDismiss(LayerShellV1 shell) {
    _dismissSurface = connection.compositor.createSurface().getOrElse((e) {
      stderr.writeln('[audio] dismiss surface: $e');
      return WlSurface(connection.context);
    });
    _dismissLayer = shell
        .getLayerSurface(
          _dismissSurface!,
          connection.output,
          LayerShellV1Layer.overlay.enumValue,
          'bardash-audio-dismiss',
        )
        .getOrElse((e) {
          stderr.writeln('[audio] dismiss layer: $e');
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
    final done = Completer<void>();
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
    } on TimeoutException {
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
        stderr.writeln('[audio] pool $i: $e');
        return WlShmPool(connection.context);
      });
      _pools[i] = pool;
      final buf = pool.createBuffer(0, _w, _h, stride, 0).getOrElse((e) {
        stderr.writeln('[audio] buffer $i: $e');
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
      stderr.writeln('[audio] dismiss pool: $e');
      return WlShmPool(connection.context);
    });
    _dismissBuffer = _dismissPool!.createBuffer(0, w, h, stride, 0).getOrElse((
      e,
    ) {
      stderr.writeln('[audio] dismiss buffer: $e');
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
    scheduleMicrotask(() {
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
      painter.drawRRect(
        Rect.fromLTWH(0, 0, _w.toDouble(), _h.toDouble()),
        10,
        10,
        Paint()..color = _bg,
      );
      painter.drawRect(
        Rect.fromLTWH(0.5, 0.5, _w - 1.0, _h - 1.0),
        Paint()
          ..color = _border
          ..style = PaintStyle.stroke
          ..strokeWidth = 1,
      );

      // Title + output row (text origins centered via ink bounds, like the
      // tray menu — drawText takes a baseline).
      const lw = 12.0;
      final titleB = painter.measureTextBounds(
        'Audio',
        size: 15,
        fontFamily: 'sans',
      );
      painter.drawText(
        'Audio',
        Offset(16, TextLayout.baselineForBounds(14, 16, titleB)),
        color: _text,
        size: 15,
      );
      final outB = painter.measureTextBounds(
        'Output',
        size: lw,
        fontFamily: 'sans',
      );
      final outBase = TextLayout.baselineForBounds(38, 14, outB);
      painter.drawText('Output', Offset(16, outBase), color: _dim, size: lw);
      final pct = (_value * 100).round();
      painter.drawText(
        '$pct%',
        Offset(_w - 56, outBase),
        color: _muted ? _dim : _text,
        size: lw,
      );

      // Output slider.
      final track = _layout.sliderTrack();
      painter.drawRRect(track, 4, 4, Paint()..color = _track);
      final fw = track.width * _value;
      if (fw > 0.5) {
        painter.drawRRect(
          Rect.fromLTWH(track.left, track.top, fw, track.height),
          4,
          4,
          Paint()..color = _fill,
        );
      }
      final thumb = _layout.thumbCenter(_value);
      painter.drawCircle(
        thumb,
        AudioPanelLayout.thumbR.toDouble(),
        Paint()..color = _thumb,
      );

      // Mic row.
      final micB = painter.measureTextBounds(
        'Mic',
        size: lw,
        fontFamily: 'sans',
      );
      final micBase = TextLayout.baselineForBounds(86, 14, micB);
      painter.drawText('Mic', Offset(16, micBase), color: _dim, size: lw);
      final micPct = (_micValue * 100).round();
      painter.drawText(
        '$micPct%',
        Offset(_w - 56, micBase),
        color: _micMuted ? _dim : _text,
        size: lw,
      );

      // Mic slider.
      final mtrack = _layout.sourceSliderTrack();
      painter.drawRRect(mtrack, 4, 4, Paint()..color = _track);
      final mfw = mtrack.width * _micValue;
      if (mfw > 0.5) {
        painter.drawRRect(
          Rect.fromLTWH(mtrack.left, mtrack.top, mfw, mtrack.height),
          4,
          4,
          Paint()..color = _micFill,
        );
      }
      final mthumb = _layout.sourceThumbCenter(_micValue);
      painter.drawCircle(
        mthumb,
        AudioPanelLayout.thumbR.toDouble(),
        Paint()..color = _thumb,
      );

      // Media player section.
      painter.drawRect(
        Rect.fromLTWH(
          AudioPanelLayout.pad.toDouble(),
          140,
          _w - AudioPanelLayout.pad * 2,
          1,
        ),
        Paint()..color = _sep,
      );
      final mediaTitle = _media.hasTrack ? _media.title : 'No media player';
      final mediaArtist = _media.hasTrack
          ? (_media.artist.isEmpty ? _media.identity : _media.artist)
          : 'MPRIS';
      final displayTitle = mediaTitle.length > 34
          ? '${mediaTitle.substring(0, 33)}…'
          : mediaTitle;
      final displayArtist = mediaArtist.length > 42
          ? '${mediaArtist.substring(0, 41)}…'
          : mediaArtist;
      final mediaTitleB = painter.measureTextBounds(
        displayTitle,
        size: lw,
        fontFamily: 'sans',
      );
      final mediaArtistB = painter.measureTextBounds(
        displayArtist,
        size: 11,
        fontFamily: 'sans',
      );
      painter.drawText(
        displayTitle,
        Offset(_w / 2 - mediaTitleB.width / 2, 151),
        color: _media.hasTrack ? _text : _dim,
        size: lw,
      );
      painter.drawText(
        displayArtist,
        Offset(_w / 2 - mediaArtistB.width / 2, 169),
        color: _dim,
        size: 11,
      );
      final previous = _layout.mediaPrevious();
      final playPause = _layout.mediaPlayPause();
      final next = _layout.mediaNext();
      _drawMediaButton(painter, previous, 'previous');
      _drawMediaButton(painter, playPause, _media.isPlaying ? 'pause' : 'play');
      _drawMediaButton(painter, next, 'next');

      // Divider + action row.
      final bTop = _layout.actionsY.toDouble();
      final bH = AudioPanelLayout.actionH.toDouble();
      final mb = _layout.muteButton();
      painter.drawRRect(
        mb,
        8,
        8,
        Paint()
          ..color = _hoverControl == 'mute'
              ? _btnHover
              : (_muted ? _mutedFill : _btn),
      );
      final muteLabel = _muted ? 'Unmute' : 'Mute';
      final mbB = painter.measureTextBounds(
        muteLabel,
        size: lw,
        fontFamily: 'sans',
      );
      painter.drawText(
        muteLabel,
        Offset(mb.left + 8, TextLayout.baselineForBounds(bTop, bH, mbB)),
        color: _text,
        size: lw,
      );
      final micb = _layout.micMuteButton();
      painter.drawRRect(
        micb,
        8,
        8,
        Paint()
          ..color = _hoverControl == 'mic-mute'
              ? _btnHover
              : (_micMuted ? _micMutedFill : _btn),
      );
      final micLabel = _micMuted ? 'Mic on' : 'Mic';
      final micBtnB = painter.measureTextBounds(
        micLabel,
        size: lw,
        fontFamily: 'sans',
      );
      painter.drawText(
        micLabel,
        Offset(micb.left + 8, TextLayout.baselineForBounds(bTop, bH, micBtnB)),
        color: _text,
        size: lw,
      );
      final mxb = _layout.mixerButton();
      painter.drawRRect(
        mxb,
        8,
        8,
        Paint()..color = _hoverControl == 'mixer' ? _btnHover : _btn,
      );
      final mxB = painter.measureTextBounds(
        'Mixer',
        size: lw,
        fontFamily: 'sans',
      );
      painter.drawText(
        'Mixer',
        Offset(mxb.left + 8, TextLayout.baselineForBounds(bTop, bH, mxB)),
        color: _text,
        size: lw,
      );
      painter.flush();
    } finally {
      painter.dispose();
    }
  }

  void _updateTransportHover() {
    _previousButton.setHovering(_hoverControl == 'previous');
    _playPauseButton.setHovering(_hoverControl == 'play-pause');
    _nextButton.setHovering(_hoverControl == 'next');
  }

  /// Draw the shared toolkit transport primitive at the popup's legacy
  /// geometry while the rest of this surface is migrated to widgets.
  void _drawMediaButton(Painter painter, Rect rect, String icon) {
    final button = icon == 'previous'
        ? _previousButton
        : icon == 'next'
        ? _nextButton
        : _playPauseButton;
    button
      ..action = icon == 'previous'
          ? TransportAction.previous
          : icon == 'next'
          ? TransportAction.next
          : (_media.isPlaying ? TransportAction.pause : TransportAction.play)
      ..x = rect.left.round()
      ..y = rect.top.round()
      ..width = rect.width.round()
      ..height = rect.height.round();
    button.draw(painter);
  }

  void _teardown() {
    _needsPaint = false;
    _paintScheduled = false;
    _presenting = false;
    _draggingSink = false;
    _draggingSource = false;
    _hoverControl = '';
    _previousButton.dispose();
    _playPauseButton.dispose();
    _nextButton.dispose();
    if (_mediaListener != null) {
      MprisClient.instance.removeListener(_mediaListener!);
      _mediaListener = null;
    }
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
