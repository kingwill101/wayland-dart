import 'package:window_toolkit/window_toolkit.dart';

import '../command.dart';
import '../metrics.dart';
import '../native/network_manager.dart';
import 'module.dart';

/// Network status via NetworkManager D-Bus (no `ip` / `nmcli` polling).
///
/// Placeholders:
///   {ipaddr} {ifname} {essid} {signalStrength} {signal} {cidr}
///   {icon}
///
/// Formats: format, format-wifi, format-ethernet, format-disconnected
class NetworkModule extends BarModule {
  @override
  String get name => 'network';

  Color _color = const Color(180, 180, 180);
  NmSnapshot _snap = NmSnapshot.disconnected;
  void Function(NmSnapshot)? _listener;
  String _lastOutput = '';

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

  @override
  void update() {
    NetworkManagerClient.instance.refresh();
  }

  void _apply() {
    if (!_snap.connected) {
      final downFmt = config['format-disconnected'] ?? 'offline';
      output = downFmt
          .replaceAll('{essid}', '')
          .replaceAll('{ifname}', '')
          .replaceAll('{ipaddr}', '')
          .replaceAll('{signalStrength}', '')
          .replaceAll('{signal}', '')
          .replaceAll('{icon}', '󰖪');
      tooltip = 'Disconnected';
      _maybeRepaint();
      return;
    }

    final state = _snap.type; // wifi | ethernet | other
    final fmt = resolveFormat(config, '{ipaddr}', state);
    final signalPct =
        _snap.signal >= 0 ? '${_snap.signal}' : '';
    final icon = switch (_snap.type) {
      'wifi' => '󰖩',
      'ethernet' => '󰈀',
      _ => '󰈁',
    };
    final essid =
        _snap.ssid.isNotEmpty ? _snap.ssid : _snap.connectionId;

    output = fmt
        .replaceAll('{ipaddr}', _snap.ip4)
        .replaceAll('{ifname}', _snap.ifname)
        .replaceAll('{essid}', essid)
        .replaceAll('{signalStrength}', signalPct)
        .replaceAll(
          '{signal}',
          signalPct.isEmpty ? '' : ' $signalPct%',
        )
        .replaceAll('{icon}', icon)
        .replaceAll('{cidr}', _snap.ip4);

    tooltip = resolveTooltip(
      [
        if (_snap.connectionId.isNotEmpty) _snap.connectionId,
        if (_snap.ifname.isNotEmpty) _snap.ifname,
        if (_snap.ip4.isNotEmpty) _snap.ip4,
        if (_snap.ssid.isNotEmpty) 'SSID ${_snap.ssid}',
        if (_snap.signal >= 0) 'Signal ${_snap.signal}%',
      ].join(' · '),
      {
        'ifname': _snap.ifname,
        'ipaddr': _snap.ip4,
        'essid': essid,
        'signalStrength': signalPct,
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
    if (onClickCmd.isNotEmpty) {
      runBarCommand(onClickCmd);
      return;
    }
    runBarCommand('nm-connection-editor');
  }
}
