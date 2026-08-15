import 'package:window_toolkit/window_toolkit.dart';

import '../command.dart';
import '../metrics.dart';
import '../native/network_manager.dart';
import '../net_speed.dart';
import '../network_popup.dart';
import 'module.dart';

/// Network status via NetworkManager D-Bus (no `ip` / `nmcli` polling).
///
/// Placeholders:
///   {ipaddr} {ifname} {essid} {signalStrength} {signal} {cidr}
///   {icon} {up} {down}
///
/// Formats: format, format-wifi, format-ethernet, format-disconnected
///
/// Left-click opens the network popup (details + live throughput) unless
/// `on_click` is set; the popup is also reachable on right-click when no
/// `on-click-right` is configured.
class NetworkModule extends BarModule {
  @override
  String get name => 'network';

  @override
  bool get needsPopupOverlay => true;

  Color _color = const Color(180, 180, 180);
  NmSnapshot _snap = NmSnapshot.disconnected;
  void Function(NmSnapshot)? _listener;
  String _lastOutput = '';
  WaylandConnection? _connection;
  int _parentWidth = 1920;
  int _parentHeight = 30;
  bool _openUpward = true;

  @override
  void init(Map<String, String> config) {
    super.init(config);
    format = resolveFormat(config, '{ipaddr}', '');
    // Signals drive updates; long interval as safety net.
    interval = parseInt(config, 'interval', 30);
    if (config.containsKey('color')) {
      _color = parseColor(config['color']!);
    }
    _listener = (s) {
      _snap = s;
      _apply();
    };
    NetworkManagerClient.instance.addListener(_listener!);
  }

  /// Called by the bar once the layer surface exists (needsPopupOverlay).
  @override
  void attachPopupOverlay(
    WaylandConnection connection, {
    int parentWidth = 1920,
    int parentHeight = 30,
    bool openUpward = true,
  }) {
    _connection = connection;
    _parentWidth = parentWidth;
    _parentHeight = parentHeight;
    _openUpward = openUpward;
  }

  @override
  void update() {
    NetworkManagerClient.instance.refresh();
    NetSpeed.sample();
  }

  void _apply() {
    NetSpeed.sample();
    final up = NetSpeed.formatRate(NetSpeed.upBps);
    final down = NetSpeed.formatRate(NetSpeed.downBps);
    if (_snap.connected) {
      NetSpeed.activeIface = _snap.ifname;
    }
    if (!_snap.connected) {
      final downFmt = config['format-disconnected'] ?? 'offline';
      output = downFmt
          .replaceAll('{essid}', '')
          .replaceAll('{ifname}', '')
          .replaceAll('{ipaddr}', '')
          .replaceAll('{signalStrength}', '')
          .replaceAll('{signal}', '')
          .replaceAll('{icon}', '󰖪')
          .replaceAll('{up}', up)
          .replaceAll('{down}', down);
      tooltip = 'Disconnected';
      _maybeRepaint();
      return;
    }

    final state = _snap.type; // wifi | ethernet | other
    final fmt = resolveFormat(config, '{ipaddr}', state);
    final signalPct = _snap.signal >= 0 ? '${_snap.signal}' : '';
    final icon = switch (_snap.type) {
      'wifi' => '󰖩',
      'ethernet' => '󰈀',
      _ => '󰈁',
    };
    final essid = _snap.ssid.isNotEmpty ? _snap.ssid : _snap.connectionId;

    output = fmt
        .replaceAll('{ipaddr}', _snap.ip4)
        .replaceAll('{ifname}', _snap.ifname)
        .replaceAll('{essid}', essid)
        .replaceAll('{signalStrength}', signalPct)
        .replaceAll('{signal}', signalPct.isEmpty ? '' : ' $signalPct%')
        .replaceAll('{icon}', icon)
        .replaceAll('{cidr}', _snap.ip4)
        .replaceAll('{up}', up)
        .replaceAll('{down}', down);

    tooltip = resolveTooltip(
      [
        if (_snap.connectionId.isNotEmpty) _snap.connectionId,
        if (_snap.ifname.isNotEmpty) _snap.ifname,
        if (_snap.ip4.isNotEmpty) _snap.ip4,
        if (_snap.ssid.isNotEmpty) 'SSID ${_snap.ssid}',
        if (_snap.signal >= 0) 'Signal ${_snap.signal}%',
        '↓ $down · ↑ $up',
      ].join(' · '),
      {
        'ifname': _snap.ifname,
        'ipaddr': _snap.ip4,
        'essid': essid,
        'signalStrength': signalPct,
        'up': up,
        'down': down,
      },
    );
    _maybeRepaint();
  }

  void _maybeRepaint() {
    if (output != _lastOutput) {
      _lastOutput = output;
      requestRepaint?.call();
    }
  }

  @override
  double measure(Painter painter) {
    final font = Font.icon(pixelSize: BarMetrics.current.fontSize);
    return painter.measureTextFont(output, font);
  }

  @override
  double draw(Painter painter, double x, double y) {
    final font = Font.icon(pixelSize: BarMetrics.current.fontSize);
    painter.drawTextFont(output, Offset(x, y), font: font, color: _color);
    return painter.measureTextFont(output, font);
  }

  @override
  void onClick(double x, double y, {int button = 0x110}) {
    final conn = _connection;
    // Left-click: configured command wins, else the network popup.
    if (button == 0x110) {
      if (onClickCmd.isNotEmpty) {
        runBarCommand(onClickCmd);
        return;
      }
      if (conn != null) {
        NetSpeed.activeIface = _snap.ifname;
        NetSpeed.sample();
        if (NetworkPopupController.isOpen) {
          NetworkPopupController.close();
        } else {
          NetworkPopupController.open(
            connection: conn,
            anchorX: hoverX.round(),
            parentWidth: _parentWidth,
            parentHeight: _parentHeight,
            openUpward: _openUpward,
          );
        }
        return;
      }
      runBarCommand('nm-connection-editor');
      return;
    }
    // Right-click with no on-click-right → same popup.
    if (onClickRightCmd.isEmpty && conn != null) {
      NetworkPopupController.open(
        connection: conn,
        anchorX: hoverX.round(),
        parentWidth: _parentWidth,
        parentHeight: _parentHeight,
        openUpward: _openUpward,
      );
    }
  }
}
