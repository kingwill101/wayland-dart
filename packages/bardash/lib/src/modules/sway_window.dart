import 'dart:convert';
import 'dart:io';

import 'package:window_toolkit/window_toolkit.dart';

import 'module.dart';

/// Sway focused window title module.
///
/// Uses `swaymsg -t get_tree --raw` to find the focused container and
/// display its title. Falls back to `i3-msg` if `swaymsg` is unavailable.
///
/// Format placeholders:
///   {title}   – window title
///   {app_id}  – app ID / WM class (or window_properties.class on XWayland)
///
/// Config keys:
///   format     – display format (default: "{title}")
///   interval   – refresh in seconds (default: 1)
///   truncate   – max title length before ellipsis (default: 0 = no limit)
///   on-click   – command on click
class SwayWindowModule extends BarModule {
  @override
  String get name => 'sway/window';

  String _title = '';
  String _appId = '';
  int _truncate = 0;
  String _binary = 'swaymsg';

  @override
  void init(Map<String, String> config) {
    super.init(config);
    format = resolveFormat(config, '{title}', '');
    interval = parseInt(config, 'interval', 1);
    _truncate = parseInt(config, 'truncate', 0);
    _binary = _detectBinary();
  }

  String _detectBinary() {
    // Prefer swaymsg, fall back to i3-msg
    for (final bin in ['swaymsg', 'i3-msg']) {
      final which = Process.runSync('which', [bin], runInShell: true);
      if (which.exitCode == 0) return bin;
    }
    return 'swaymsg';
  }

  @override
  void update() {
    try {
      final result = Process.runSync(
        _binary,
        ['-t', 'get_tree', '--raw'],
        runInShell: true,
      );
      if (result.exitCode != 0) {
        output = 'N/A';
        return;
      }

      final tree = jsonDecode(result.stdout as String);
      final focused = _findFocusedNode(tree);
      if (focused == null) {
        output = '';
        return;
      }

      _title = focused['name']?.toString() ?? '';
      _appId = focused['app_id']?.toString() ??
          focused['window_properties']?['class']?.toString() ??
          '';

      final displayTitle = _truncate > 0 && _title.length > _truncate
          ? '${_title.substring(0, _truncate)}\u2026'
          : _title;

      output = format
          .replaceAll('{title}', displayTitle)
          .replaceAll('{app_id}', _appId);
    } catch (_) {
      output = 'ERR';
    }
  }

  /// Recursively find the focused container node in the Sway tree.
  dynamic _findFocusedNode(dynamic node) {
    if (node == null) return null;
    // A focused container
    if (node['focused'] == true && node['type'] == 'con') {
      return node;
    }
    // Check regular children
    if (node['nodes'] is List) {
      for (final child in node['nodes']) {
        final found = _findFocusedNode(child);
        if (found != null) return found;
      }
    }
    // Check floating nodes
    if (node['floating_nodes'] is List) {
      for (final child in node['floating_nodes']) {
        final found = _findFocusedNode(child);
        if (found != null) return found;
      }
    }
    return null;
  }

  @override
  double draw(Painter painter, double x, double y) {
    painter.drawText(output, Offset(x, y));
    return painter.measureText(output).width;
  }
}
