/// A click-to-open network panel for bardash.
///
/// Shows connection details + live link throughput + quick actions.
/// Layer ownership and presentation are provided by the toolkit popup host.
library;

import 'dart:async' as dart_async;
import 'dart:io';

import 'package:window_toolkit/window_toolkit.dart';

import 'native/network_manager.dart';
import 'net_speed.dart';
import 'speed_test_popup.dart';

/// Pure layout + hit-testing for the network panel.
class NetworkPanelLayout {
  final int width;
  final int height;

  NetworkPanelLayout({int? width, int? height})
    : width = width ?? 260,
      height = height ?? 190;

  static const pad = 12;
  static const rowH = 20;
  static const btnH = 24;

  int get btnW => ((width - pad * 3) / 2).round();

  Rect btnSpeedTest() => Rect.fromLTWH(
    pad.toDouble(),
    (height - pad - btnH).toDouble(),
    btnW.toDouble(),
    btnH.toDouble(),
  );

  Rect btnSettings() => Rect.fromLTWH(
    (pad + btnW + pad).toDouble(),
    (height - pad - btnH).toDouble(),
    btnW.toDouble(),
    btnH.toDouble(),
  );

  bool _inRect(Rect b, double x, double y) =>
      x >= b.left && x <= b.right && y >= b.top && y <= b.bottom;

  bool hitSpeedTest(double x, double y) => _inRect(btnSpeedTest(), x, y);
  bool hitSettings(double x, double y) => _inRect(btnSettings(), x, y);
}

/// Toolkit-owned network popup content. The overlay only handles placement;
/// labels and actions remain ordinary widgets so CSS and hover state apply.
class NetworkPanelWidget extends Widget {
  final int panelWidth;
  final int panelHeight;
  final VoidCallback onSpeedTest;
  final VoidCallback onSettings;

  late final Label icon;
  late final Label title;
  late final Label interfaceLabel;
  late final Label interfaceValue;
  late final Label ipLabel;
  late final Label ipValue;
  late final Label signalLabel;
  late final Label signalValue;
  late final Label downloadLabel;
  late final Label downloadValue;
  late final Label uploadLabel;
  late final Label uploadValue;
  late final Separator divider;
  late final Button speedTestButton;
  late final Button settingsButton;

  @override
  late final List<Widget> children;

  NetworkPanelWidget({
    this.panelWidth = 260,
    this.panelHeight = 190,
    required this.onSpeedTest,
    required this.onSettings,
  }) {
    styleId = 'network-popup';
    addClass('popup');
    addClass('network-popup');
    icon = Label('󰖩', font: const Font.icon(pixelSize: 18))
      ..styleId = 'network-icon'
      ..addClass('network-icon');
    title = Label('Network', fontSize: 15)
      ..styleId = 'network-title'
      ..addClass('popup-title');

    interfaceLabel = _label('Interface', 'network-interface-label');
    interfaceValue = _value('—', 'network-interface-value');
    ipLabel = _label('IP', 'network-ip-label');
    ipValue = _value('—', 'network-ip-value');
    signalLabel = _label('Signal', 'network-signal-label');
    signalValue = _value('—', 'network-signal-value');
    downloadLabel = _label('↓', 'network-download-label');
    downloadValue = _value('—', 'network-download-value')
      ..addClass('network-download');
    uploadLabel = _label('↑', 'network-upload-label');
    uploadValue = _value('—', 'network-upload-value')
      ..addClass('network-upload');
    divider = Separator(lineWidth: 1, margin: 0)
      ..styleId = 'network-divider'
      ..addClass('network-divider');
    speedTestButton = Button('Speed Test', onPressed: onSpeedTest, padding: 8)
      ..styleId = 'network-speed-test'
      ..addClass('network-action');
    settingsButton = Button('Settings', onPressed: onSettings, padding: 8)
      ..styleId = 'network-settings'
      ..addClass('network-action');

    children = [
      icon,
      title,
      interfaceLabel,
      interfaceValue,
      ipLabel,
      ipValue,
      signalLabel,
      signalValue,
      downloadLabel,
      downloadValue,
      uploadLabel,
      uploadValue,
      divider,
      speedTestButton,
      settingsButton,
    ];
    speedTestButton.initState();
    settingsButton.initState();
  }

  Label _label(String text, String id) => Label(text, fontSize: 12)
    ..styleId = id
    ..addClass('network-label');

  Label _value(String text, String id) => Label(text, fontSize: 12)
    ..styleId = id
    ..addClass('network-value');

  @override
  Style styleRole() => Style(
    color: const Color(235, 235, 240),
    backgroundColor: const Color(30, 30, 34),
    borderColor: const Color(80, 80, 90),
    borderWidth: 1,
    borderRadius: 10,
  );

  void update({
    required NmSnapshot snapshot,
    required String down,
    required String up,
  }) {
    final ssid = snapshot.ssid.isNotEmpty
        ? snapshot.ssid
        : snapshot.connectionId;
    title.text = ssid.isEmpty ? 'Network' : ssid;
    icon.text = snapshot.type == 'ethernet' ? '󰈀' : '󰖩';
    interfaceValue.text = snapshot.ifname.isEmpty ? '—' : snapshot.ifname;
    ipValue.text = snapshot.ip4.isEmpty ? '—' : snapshot.ip4;
    signalValue.text = snapshot.signal >= 0 ? '${snapshot.signal}%' : '—';
    downloadValue.text = down;
    uploadValue.text = up;
  }

  @override
  void measure(Painter painter) {
    for (final child in children) {
      child.measure(painter);
    }
    width = panelWidth;
    height = panelHeight;
  }

  @override
  void performLayout(int containerWidth) {
    width = panelWidth;
    height = panelHeight;
    final left = styledPaddingLeft(12);
    final right = styledPaddingRight(12);
    final inner = (width - left - right).clamp(1, width);

    void place(Widget child, int px, int py, int pw, int ph) {
      child
        ..x = x + px
        ..y = y + py
        ..width = pw
        ..height = ph;
    }

    place(icon, left, 8, 22, 22);
    place(title, left + 28, 8, inner - 28, 22);
    final rows = <(Label, Label)>[
      (interfaceLabel, interfaceValue),
      (ipLabel, ipValue),
      (signalLabel, signalValue),
      (downloadLabel, downloadValue),
      (uploadLabel, uploadValue),
    ];
    for (var i = 0; i < rows.length; i++) {
      final (label, value) = rows[i];
      final py = 39 + i * 20;
      place(label, left, py, inner ~/ 2, 18);
      place(value, width - right - value.width, py, value.width, 18);
    }
    place(divider, left, 142, inner, 1);
    final buttonY = height - styledPaddingBottom(12) - 24;
    const buttonGap = 12;
    final buttonWidth = ((inner - buttonGap) / 2).round();
    place(speedTestButton, left, buttonY, buttonWidth, 24);
    place(
      settingsButton,
      left + buttonWidth + buttonGap,
      buttonY,
      inner - buttonWidth - buttonGap,
      24,
    );
  }

  @override
  void draw(Painter painter) {
    drawStyledBox(painter);
    for (final child in children) {
      child.draw(painter);
    }
  }

  List<Button> get buttons => [speedTestButton, settingsButton];

  Button? buttonAt(int px, int py) {
    for (final button in buttons.reversed) {
      if (button.hitTest(px, py)) return button;
    }
    return null;
  }

  void updateButtonHover(int px, int py) {
    for (final button in buttons) {
      button.setHovering(button.hitTest(px, py));
    }
  }

  @override
  bool hitTest(int px, int py) {
    if (!super.hitTest(px, py)) return false;
    for (final child in children.reversed) {
      if (child.hitTest(px, py)) return true;
    }
    return true;
  }
}

class NetworkPopupController {
  static NetworkPopupOverlay? _active;
  static int _generation = 0;

  // Treat a popup that is still waiting for compositor configure as active.
  // Otherwise a second click can destroy its surfaces while show() is
  // suspended, and the first continuation observes null handles.
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

    late final NetworkPopupOverlay overlay;
    overlay = NetworkPopupOverlay(
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
      stderr.writeln('[network] popup failed: $e');
      overlay.destroy();
      if (identical(_active, overlay)) _active = null;
    }
    if (identical(_active, overlay) && !overlay.isOpen) {
      _active = null;
    }
    if (gen != _generation) return;
  }
}

class NetworkPopupOverlay {
  final LayerPopupHost popupHost;
  final int anchorX;
  final int parentWidth;
  final int parentHeight;
  final bool openUpward;
  final void Function()? onClosed;

  LayerPopup? _popup;
  late final NetworkPanelWidget _view;
  late final void Function(NmSnapshot) _networkListener;
  bool _open = false;
  dart_async.Timer? _tick;

  // Sizes.
  static const _w = 260;
  static const _h = 190;

  NetworkPopupOverlay({
    required this.popupHost,
    required this.anchorX,
    this.parentWidth = 1920,
    this.parentHeight = 30,
    this.openUpward = true,
    this.onClosed,
  }) {
    _view = NetworkPanelWidget(
      panelWidth: _w,
      panelHeight: _h,
      onSpeedTest: _openSpeedTest,
      onSettings: () {
        _run('Settings', 'nm-connection-editor');
        hide();
      },
    );
    _networkListener = (_) {
      _refreshView();
      _scheduleRepaint();
    };
    _refreshView();
  }

  bool get isOpen => _open;

  Future<void> show() async {
    _popup = popupHost.create(
      content: _view,
      placement: BarPopupPlacement.forBar(
        anchorX: anchorX,
        parentWidth: parentWidth,
        width: _w,
        height: _h,
        openUpward: openUpward,
      ),
      dismissPlacement: LayerSurfacePlacement(
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
      ),
      background: const Color(0, 0, 0, 0),
      onEvent: _handlePopupEvent,
      onClosed: _onPopupClosed,
    );
    if (!await _popup!.show()) {
      _popup = null;
      return;
    }

    // Live snapshot + throughput refreshes.
    NetworkManagerClient.instance.addListener(_networkListener);
    _tick = dart_async.Timer.periodic(const Duration(seconds: 1), (_) {
      NetSpeed.sample();
      _refreshView();
      _scheduleRepaint();
    });

    _open = true;
    stderr.writeln('[network] open overlay $_w x $_h anchorX=$anchorX');
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
    // Content input is routed by LayerPopup's shared WidgetHostController.
    // Keeping this policy callback focused on dismissal prevents every
    // popup from growing a second button/hover implementation.
    return false;
  }

  void _openSpeedTest() {
    NetworkPopupController.close();
    SpeedTestController.open(
      popupHost: popupHost,
      anchorX: anchorX,
      parentWidth: parentWidth,
      parentHeight: parentHeight,
      openUpward: openUpward,
    );
  }

  void _onPopupClosed() {
    _open = false;
    _popup = null;
    NetworkManagerClient.instance.removeListener(_networkListener);
    _tick?.cancel();
    _tick = null;
    onClosed?.call();
  }

  String? _resolveCommand(String cmd) {
    try {
      final r = Process.runSync('which', [cmd], runInShell: false);
      if (r.exitCode == 0) return cmd;
    } catch (_) {}
    return null;
  }

  void _run(String label, String cmd) {
    final exe = _resolveCommand(cmd);
    if (exe == null) {
      stderr.writeln('[network] $label: $cmd not found');
      return;
    }
    try {
      stderr.writeln('[network] $label: $exe');
      Process.run(exe, const [], runInShell: false);
    } on ProcessException catch (e) {
      stderr.writeln('[network] $label failed: $e');
    }
  }

  void _scheduleRepaint() {
    _popup?.requestRepaint();
  }

  void _refreshView() {
    final snapshot = NetworkManagerClient.instance.last;
    _view.update(
      snapshot: snapshot,
      down: NetSpeed.formatRate(NetSpeed.downBps),
      up: NetSpeed.formatRate(NetSpeed.upBps),
    );
  }
}
