import 'package:window_toolkit/window_toolkit.dart';

import '../metrics.dart';
import '../native/statvfs.dart';
import 'module.dart';

/// Disk usage via libc `statvfs` (no `df` subprocess).
///
/// Placeholders: `{used_pct}`, `{total}`, `{used}`, `{avail}`, `{path}`
///
/// Config: `path` (mount point, default `/`), `format`, `interval`
class DiskModule extends BarModule {
  @override
  String get name => 'disk';

  String _path = '/';
  String _display = '';

  @override
  void init(Map<String, String> config) {
    super.init(config);
    format = resolveFormat(config, 'Disk {used_pct}%', '');
    interval = parseInt(config, 'interval', 10);
    _path = config['path'] ?? _path;
  }

  @override
  void update() {
    final u = statVfsPath(_path);
    if (u == null) {
      _display = 'ERR';
      output = _display;
      tooltip = 'statvfs failed for $_path';
      return;
    }
    _display = format
        .replaceAll('{used_pct}', '${u.usedPercent}')
        .replaceAll('{total}', formatBytesHuman(u.totalBytes))
        .replaceAll('{used}', formatBytesHuman(u.usedBytes))
        .replaceAll('{avail}', formatBytesHuman(u.availBytes))
        .replaceAll('{path}', _path);
    output = _display;
    tooltip = resolveTooltip(
      '$_path: ${formatBytesHuman(u.usedBytes)} / '
      '${formatBytesHuman(u.totalBytes)} (${u.usedPercent}%)',
      {
        'used_pct': '${u.usedPercent}',
        'total': formatBytesHuman(u.totalBytes),
        'used': formatBytesHuman(u.usedBytes),
        'avail': formatBytesHuman(u.availBytes),
        'path': _path,
      },
    );
  }

  @override
  double measure(Painter painter) {
    if (_display.isEmpty) return 0;
    final font = Font.ui(pixelSize: BarMetrics.current.fontSize);
    return painter.measureTextFont(_display, font);
  }

  @override
  double draw(Painter painter, double x, double y) {
    if (_display.isEmpty) return 0;
    final font = Font.ui(pixelSize: BarMetrics.current.fontSize);
    painter.drawTextFont(_display, Offset(x, y), font: font);
    return painter.measureTextFont(_display, font);
  }
}
