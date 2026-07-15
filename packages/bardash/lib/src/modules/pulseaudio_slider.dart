import 'dart:io';

import 'package:window_toolkit/window_toolkit.dart';

import 'module.dart';

/// PulseAudio volume slider rendered as an inline level bar.
///
/// Draws a horizontal bar showing current volume level. Click toggles
/// mute. The bar width is configurable so it acts as a visual "slider".
///
/// Format placeholders:
///   {volume}   – volume percent
///   {icon}     – volume icon (// or muted icon)
///   {muted}    – "yes" or "no"
///
/// Config keys:
///   format         – text format (default: "{icon}")
///   bar-width      – pixel width of the level bar (default: 40)
///   bar-height     – pixel height of the level bar (default: 8)
///   bar-color      – fill color hex (default: "88c0d0")
///   bar-bg-color   – track background color hex (default: "3b4252")
///   interval       – refresh in seconds (default: 2)
///   on-click       – custom command on click
class PulseaudioSliderModule extends BarModule {
  @override
  String get name => 'pulseaudio-slider';

  int _volume = 0;
  bool _muted = false;
  int _barWidth = 40;
  int _barHeight = 8;
  late Color _barColor;
  late Color _barBgColor;

  @override
  void init(Map<String, String> config) {
    super.init(config);
    format = resolveFormat(config, '{icon}', '');
    interval = parseInt(config, 'interval', 2);
    _barWidth = parseInt(config, 'bar-width', 40);
    _barHeight = parseInt(config, 'bar-height', 8);
    _barColor = config.containsKey('bar-color')
        ? parseColor(config['bar-color']!)
        : const Color(0x88, 0xc0, 0xd0);
    _barBgColor = config.containsKey('bar-bg-color')
        ? parseColor(config['bar-bg-color']!)
        : const Color(0x3b, 0x42, 0x52);
  }

  @override
  void update() {
    try {
      var result = _runPactl();
      if (result == null) {
        result = _runAmixer();
      }
      if (result == null) {
        output = format.replaceAll('{icon}', 'ERR');
        return;
      }
      _volume = result.$1;
      _muted = result.$2;
    } catch (_) {
      output = format.replaceAll('{icon}', 'ERR');
    }
  }

  (int, bool)? _runPactl() {
    final volResult = Process.runSync(
        'pactl', ['get-sink-volume', '@DEFAULT_SINK@'],
        runInShell: true);
    if (volResult.exitCode != 0) return null;
    final volOut = volResult.stdout as String;
    final volMatch = RegExp(r'(\d+)%').firstMatch(volOut);
    if (volMatch == null) return null;
    final volume = int.parse(volMatch.group(1)!);

    final muteResult = Process.runSync(
        'pactl', ['get-sink-mute', '@DEFAULT_SINK@'],
        runInShell: true);
    final muted = muteResult.exitCode == 0 &&
        (muteResult.stdout as String).contains('Mute: yes');
    return (volume, muted);
  }

  (int, bool)? _runAmixer() {
    final result = Process.runSync('amixer', ['get', 'Master'],
        runInShell: true);
    if (result.exitCode != 0) return null;
    final out = result.stdout as String;
    final volMatch = RegExp(r'\[(\d+)%\]').firstMatch(out);
    if (volMatch == null) return null;
    final volume = int.parse(volMatch.group(1)!);
    final muted = out.contains('[off]');
    return (volume, muted);
  }

  @override
  double measure(Painter painter) {
    final iconWidth = painter.measureText(output, size: 14).width;
    return iconWidth + 4 + _barWidth.toDouble();
  }

  @override
  double draw(Painter painter, double x, double y) {
    // Draw icon/text
    final icon = _muted
        ? '\u{f026}' // 
        : getIcon(_volume, ['\u{f025}', '\u{f027}', '\u{f028}']);
    final text = format.replaceAll('{icon}', icon);
    painter.drawText(text, Offset(x, y), color: const Color(0xc8, 0xc8, 0xc8));
    final textWidth = painter.measureText(text).width;

    // Draw level bar
    final barX = x + textWidth + 4;
    final barY = y + (14 - _barHeight) / 2;

    // Track background
    painter.drawRect(
      Rect.fromLTWH(barX, barY, _barWidth.toDouble(), _barHeight.toDouble()),
      Paint()..color = _barBgColor,
    );

    // Filled portion
    if (_volume > 0) {
      final fillWidth = _volume / 100.0 * _barWidth;
      painter.drawRect(
        Rect.fromLTWH(barX, barY, fillWidth, _barHeight.toDouble()),
        Paint()..color = _muted ? const Color(0x60, 0x60, 0x60) : _barColor,
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
    // Simple toggle mute on click
    final arg = _muted ? '0' : '1';
    Process.runSync('pactl', ['set-sink-mute', '@DEFAULT_SINK@', arg],
        runInShell: true);
    update();
  }
}
