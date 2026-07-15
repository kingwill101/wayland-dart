import 'package:window_toolkit/window_toolkit.dart';

import '../metrics.dart';
import '../native/modem_manager_client.dart';
import 'module.dart';

/// Mobile broadband (WWAN) via ModemManager D-Bus (no `mmcli`).
///
/// Placeholders: `{state}`, `{signal}`, `{operator}`, `{technology}`,
/// `{imei}`, `{icon}`
///
/// Config: `modem-index` (default 0), `format`, `format-disabled`
class WwanModule extends BarModule {
  @override
  String get name => 'wwan';

  ModemSnapshot _snap = ModemSnapshot.empty;
  void Function(ModemSnapshot)? _listener;
  String _lastOut = '';

  @override
  void init(Map<String, String> config) {
    super.init(config);
    format = resolveFormat(config, '{icon} {signal}%', '');
    interval = parseInt(config, 'interval', 30);
    final idx = parseInt(config, 'modem-index', 0);
    ModemManagerClient.instance.setModemIndex(idx);
    _listener = (s) {
      _snap = s;
      _apply();
    };
    ModemManagerClient.instance.addListener(_listener!);
  }

  @override
  void update() {
    ModemManagerClient.instance.refresh();
  }

  void _apply() {
    if (!_snap.available || !_snap.hasModem) {
      output = '';
      tooltip = '';
      _maybeRepaint();
      return;
    }

    if (_snap.disabled) {
      final disabledFormat = resolveFormat(config, '', 'disabled');
      output = disabledFormat.replaceAll('{icon}', '\u{f1eb}');
      tooltip = 'Modem ${_snap.state}';
      _maybeRepaint();
      return;
    }

    final icon = getIcon(
      _snap.signal,
      ['\u{f1eb}', '\u{f1eb}', '\u{f1eb}', '\u{f1eb}'],
    );

    output = format
        .replaceAll('{state}', _snap.state)
        .replaceAll('{signal}', '${_snap.signal}')
        .replaceAll('{operator}', _snap.operatorName)
        .replaceAll('{technology}', _snap.technology)
        .replaceAll('{imei}', _snap.imei)
        .replaceAll('{icon}', icon);

    tooltip = resolveTooltip(
      [
        if (_snap.operatorName.isNotEmpty) _snap.operatorName,
        if (_snap.technology.isNotEmpty) _snap.technology,
        if (_snap.state.isNotEmpty) _snap.state,
        'Signal ${_snap.signal}%',
      ].join(' · '),
      {
        'state': _snap.state,
        'signal': '${_snap.signal}',
        'operator': _snap.operatorName,
        'technology': _snap.technology,
      },
    );
    _maybeRepaint();
  }

  void _maybeRepaint() {
    if (output != _lastOut) {
      _lastOut = output;
      requestRepaint?.call();
    }
  }

  @override
  double measure(Painter painter) {
    if (output.isEmpty) return 0;
    final font = Font.ui(pixelSize: BarMetrics.current.fontSize);
    return painter.measureTextFont(output, font);
  }

  @override
  double draw(Painter painter, double x, double y) {
    if (output.isEmpty) return 0;
    final font = Font.ui(pixelSize: BarMetrics.current.fontSize);
    painter.drawTextFont(output, Offset(x, y), font: font);
    return painter.measureTextFont(output, font);
  }
}
