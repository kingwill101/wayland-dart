import '../native/geoclue_client.dart';
import 'module.dart';

/// GPS / location via GeoClue2 D-Bus (no `gpspipe`).
///
/// Placeholders: `{lat}`, `{lon}`, `{altitude}`, `{speed}`, `{fix}`,
/// `{icon}`, `{accuracy}`, `{description}`
///
/// Hides when no fix. Config: `format`, `interval`
class GpsModule extends BarModule {
  @override
  String get name => 'gps';

  GeoSnapshot _snap = GeoSnapshot.empty;
  void Function(GeoSnapshot)? _listener;
  String _lastOut = '';

  @override
  void init(Map<String, String> config) {
    super.init(config);
    format = resolveFormat(config, '{lat},{lon}', '');
    interval = parseInt(config, 'interval', 30);
    _listener = (s) {
      _snap = s;
      _apply();
    };
    GeoclueClient.instance.addListener(_listener!);
  }

  @override
  void update() {
    GeoclueClient.instance.refresh();
  }

  void _apply() {
    if (!_snap.available || !_snap.hasFix) {
      output = '';
      tooltip = _snap.available
          ? 'Waiting for location fix'
          : 'GeoClue not available';
      _maybeRepaint();
      return;
    }

    final fix = _snap.accuracy > 0 && _snap.accuracy < 50
        ? '3d'
        : (_snap.hasFix ? '2d' : 'none');
    final icon = '\u{f0ac}';

    output = format
        .replaceAll('{lat}', _snap.lat.toStringAsFixed(4))
        .replaceAll('{lon}', _snap.lon.toStringAsFixed(4))
        .replaceAll('{altitude}', _snap.altitude.toStringAsFixed(0))
        .replaceAll('{speed}', _snap.speedKmh.toStringAsFixed(0))
        .replaceAll('{satellites}', '') // not exposed by GeoClue
        .replaceAll('{fix}', fix)
        .replaceAll('{icon}', icon)
        .replaceAll('{accuracy}', _snap.accuracy.toStringAsFixed(0))
        .replaceAll('{description}', _snap.description);

    tooltip = resolveTooltip(
      [
        '${_snap.lat.toStringAsFixed(5)}, ${_snap.lon.toStringAsFixed(5)}',
        if (_snap.altitude != 0) 'alt ${_snap.altitude.toStringAsFixed(0)}m',
        if (_snap.accuracy > 0) '±${_snap.accuracy.toStringAsFixed(0)}m',
        if (_snap.description.isNotEmpty) _snap.description,
      ].join(' · '),
      {
        'lat': _snap.lat.toStringAsFixed(4),
        'lon': _snap.lon.toStringAsFixed(4),
        'fix': fix,
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
}
