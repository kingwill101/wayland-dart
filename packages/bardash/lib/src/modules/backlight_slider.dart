import 'dart:io';

import 'package:window_toolkit/window_toolkit.dart';

import 'module.dart';

/// Backlight brightness slider rendered as an inline level bar.
///
/// Draws a horizontal bar showing current brightness level. Scrolling over
/// the module (when scroll support is wired) or clicking toggles through
/// preset levels.
///
/// Format placeholders:
///   {percent}   – brightness percent
///   {icon}      – sun icon
///
/// Config keys:
///   format         – text format (default: "{icon} {percent}%")
///   bar-width      – pixel width of the level bar (default: 40)
///   bar-height     – pixel height of the level bar (default: 8)
///   bar-color      – fill color hex (default: "ebcb8b")
///   bar-bg-color   – track background hex (default: "3b4252")
///   interval       – refresh in seconds (default: 3)
///   device         – backlight device name (default: auto-detect)
///   on-click       – custom command on click
class BacklightSliderModule extends BarModule {
  @override
  String get name => 'backlight-slider';

  int _percent = 0;
  int _barWidth = 40;
  int _barHeight = 8;
  String? _device;
  late Color _barColor;
  late Color _barBgColor;

  @override
  void init(Map<String, String> config) {
    super.init(config);
    format = resolveFormat(config, '{icon} {percent}%', '');
    interval = parseInt(config, 'interval', 3);
    _barWidth = parseInt(config, 'bar-width', 40);
    _barHeight = parseInt(config, 'bar-height', 8);
    _device = config['device'];
    _barColor = config.containsKey('bar-color')
        ? parseColor(config['bar-color']!)
        : const Color(0xeb, 0xcb, 0x8b);
    _barBgColor = config.containsKey('bar-bg-color')
        ? parseColor(config['bar-bg-color']!)
        : const Color(0x3b, 0x42, 0x52);
  }

  @override
  void update() {
    try {
      final device = _resolveDevice();
      if (device == null) {
        output = format
            .replaceAll('{percent}', 'N/A')
            .replaceAll('{icon}', '\u{f185}');
        return;
      }

      final brightness = int.tryParse(
        File('$device/brightness').readAsStringSync().trim(),
      );
      final maxBrightness = int.tryParse(
        File('$device/max_brightness').readAsStringSync().trim(),
      );

      if (brightness == null || maxBrightness == null || maxBrightness == 0) {
        output = format
            .replaceAll('{percent}', 'N/A')
            .replaceAll('{icon}', '\u{f185}');
        return;
      }

      _percent = (brightness / maxBrightness * 100).round();

      output = format
          .replaceAll('{percent}', '$_percent')
          .replaceAll('{icon}', '\u{f185}');
    } catch (_) {
      output = format
          .replaceAll('{percent}', 'ERR')
          .replaceAll('{icon}', '\u{f185}');
    }
  }

  String? _resolveDevice() {
    if (_device != null) {
      final path = '/sys/class/backlight/$_device';
      if (Directory(path).existsSync()) return path;
      return null;
    }

    try {
      final dir = Directory('/sys/class/backlight');
      if (!dir.existsSync()) return null;
      final entries = dir.listSync();
      if (entries.isEmpty) return null;
      return entries.first.path;
    } catch (_) {
      return null;
    }
  }

  @override
  double measure(Painter painter) {
    final textWidth = painter.measureText(output, size: 14).width;
    return textWidth + 4 + _barWidth.toDouble();
  }

  @override
  double draw(Painter painter, double x, double y) {
    // Draw text label
    painter.drawText(output, Offset(x, y), color: const Color(0xc8, 0xc8, 0xc8));
    final textWidth = painter.measureText(output).width;

    // Draw level bar
    final barX = x + textWidth + 4;
    final barY = y + (14 - _barHeight) / 2;

    // Track background
    painter.drawRect(
      Rect.fromLTWH(barX, barY, _barWidth.toDouble(), _barHeight.toDouble()),
      Paint()..color = _barBgColor,
    );

    // Filled portion
    if (_percent > 0) {
      final fillWidth = _percent / 100.0 * _barWidth;
      painter.drawRect(
        Rect.fromLTWH(barX, barY, fillWidth, _barHeight.toDouble()),
        Paint()..color = _barColor,
      );
    }

    return barX + _barWidth - x;
  }

  @override
  bool get hasClick => true;

  @override
  void onClick(double x, double y, {int button = 0x110}) {
    if (onClickCmd.isNotEmpty) {
      Process.runSync(onClickCmd, [], runInShell: true);
      return;
    }
    // Cycle through brightness levels: 0%, 25%, 50%, 75%, 100%
    final levels = [0, 25, 50, 75, 100];
    int next = 0;
    for (final lvl in levels) {
      if (_percent < lvl) {
        next = lvl;
        break;
      }
    }
    _setBrightness(next);
  }

  void _setBrightness(int percent) {
    final device = _resolveDevice();
    if (device == null) return;

    try {
      final maxFile = File('$device/max_brightness');
      final maxBrightness =
          int.tryParse(maxFile.readAsStringSync().trim()) ?? 100;
      final value = (maxBrightness * percent / 100).round().clamp(1, maxBrightness);
      File('$device/brightness').writeAsStringSync('$value\n');
    } catch (_) {}
  }
}
