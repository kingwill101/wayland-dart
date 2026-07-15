import 'dart:convert';
import 'dart:io';

import 'package:window_toolkit/window_toolkit.dart';

import 'module.dart';

/// Sway keyboard layout / language indicator.
///
/// Uses `swaymsg -t get_inputs --raw` to find the active keyboard layout.
///
/// Format placeholders:
///   {layout}   – keyboard layout name (e.g. "us", "de")
///   {variant}  – layout variant (e.g. "dvorak", empty if none)
///   {short}    – first 2 uppercase chars of layout (e.g. "US", "DE")
///
/// Config keys:
///   format     – display format (default: "{short}")
///   interval   – refresh in seconds (default: 1)
///   on-click   – command on click (e.g. "swaymsg input * xkb_layout us,de")
class SwayLanguageModule extends BarModule {
  @override
  String get name => 'sway/language';

  String _layout = '';
  String _variant = '';
  String _binary = 'swaymsg';

  @override
  void init(Map<String, String> config) {
    super.init(config);
    format = resolveFormat(config, '{short}', '');
    interval = parseInt(config, 'interval', 1);
    _binary = _detectBinary();
  }

  String _detectBinary() {
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
        ['-t', 'get_inputs', '--raw'],
        runInShell: true,
      );
      if (result.exitCode != 0) {
        output = 'N/A';
        return;
      }

      final inputs = jsonDecode(result.stdout as String) as List;
      for (final input in inputs) {
        if (input['type'] != 'keyboard') continue;
        final xkbActive = input['xkb_active_layout_name'];
        if (xkbActive == null) continue;

        // xkb_active_layout_name is like "English (US)" or "German"
        // We can parse the layout from xkb_active_layout_index and xkb_layout_names
        final index = input['xkb_active_layout_index'];
        final names = input['xkb_layout_names'];
        if (names is List && index is int && index < names.length) {
          final name = names[index].toString();
          final parts = name.split('(');
          _layout = parts[0].trim().toLowerCase();
          _variant = parts.length > 1
              ? parts[1].replaceAll(')', '').trim().toLowerCase()
              : '';
        } else if (xkbActive is String) {
          // Fallback: parse from the display name
          _layout = xkbActive.toString().toLowerCase();
          _variant = '';
        }

        // Found the first keyboard, use it
        break;
      }

      if (_layout.isEmpty) {
        output = '';
        return;
      }

      output = format
          .replaceAll('{layout}', _layout)
          .replaceAll('{variant}', _variant)
          .replaceAll(
              '{short}', _layout.length >= 2 ? _layout.substring(0, 2).toUpperCase() : _layout.toUpperCase());
    } catch (_) {
      output = 'ERR';
    }
  }

  @override
  double draw(Painter painter, double x, double y) {
    painter.drawText(output, Offset(x, y));
    return painter.measureText(output).width;
  }
}
