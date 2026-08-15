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
      output = 'ERR';
      tooltip = 'statvfs failed for $_path';
      return;
    }
    output = format
        .replaceAll('{used_pct}', '${u.usedPercent}')
        .replaceAll('{total}', formatBytesHuman(u.totalBytes))
        .replaceAll('{used}', formatBytesHuman(u.usedBytes))
        .replaceAll('{avail}', formatBytesHuman(u.availBytes))
        .replaceAll('{path}', _path);
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
}
