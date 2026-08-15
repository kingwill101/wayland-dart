import 'dart:io';

import 'package:window_toolkit/window_toolkit.dart';

import '../command.dart';
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

  @override
  bool get showsGraphics => true;

  int _volume = 0;
  bool _muted = false;
  int _barWidth = 40;
  int _barHeight = 8;
  int _scrollStep = 5;
  late Color _barColor;
  late Color _barBgColor;
  late final TextRuns _textWidget;
  late final ProgressBar _levelWidget;

  /// Icon glyph for the current volume/state.
  String get _levelIcon => _muted
      ? '\u{f026}' // muted
      : getIcon(_volume, ['\u{f025}', '\u{f027}', '\u{f028}']);

  @override
  void init(Map<String, String> config) {
    super.init(config);
    format = resolveFormat(config, '{icon}', '');
    interval = parseInt(config, 'interval', 2);
    _scrollStep = parseInt(config, 'scroll-step', 5).clamp(1, 25);
    _barWidth = parseInt(config, 'bar-width', 40);
    _barHeight = parseInt(config, 'bar-height', 8);
    _barColor = config.containsKey('bar-color')
        ? parseColor(config['bar-color']!)
        : const Color(0x88, 0xc0, 0xd0);
    _barBgColor = config.containsKey('bar-bg-color')
        ? parseColor(config['bar-bg-color']!)
        : const Color(0x3b, 0x42, 0x52);
    _textWidget = TextRuns('');
    _levelWidget = ProgressBar(
      barWidth: _barWidth,
      barHeight: _barHeight,
      showText: false,
      fillColor: _barColor,
      backgroundColor: _barBgColor,
    );
    widget = HBox(spacing: 4, children: [_textWidget, _levelWidget]);
  }

  void _syncWidget() {
    _textWidget.text = output;
    _levelWidget.value = _volume;
    _levelWidget.fillColor = _muted ? const Color(0x60, 0x60, 0x60) : _barColor;
    requestRepaint?.call();
  }

  @override
  void update() {
    try {
      var result = _runPactl();
      if (result == null) {
        result = _runAmixer();
      }
      if (result == null) {
        // error icon
        output = format.replaceAll('{icon}', '\u{f03a}');
        _syncWidget();
        return;
      }
      _volume = result.$1;
      _muted = result.$2;
      // Compose the real (icon + text) string so measure/draw agree.
      output = format.replaceAll('{icon}', _levelIcon);
      _syncWidget();
    } catch (_) {
      output = format.replaceAll('{icon}', '\u{f03a}');
      _syncWidget();
    }
  }

  (int, bool)? _runPactl() {
    final volResult = Process.runSync('pactl', [
      'get-sink-volume',
      '@DEFAULT_SINK@',
    ], runInShell: true);
    if (volResult.exitCode != 0) return null;
    final volOut = volResult.stdout as String;
    final volMatch = RegExp(r'(\d+)%').firstMatch(volOut);
    if (volMatch == null) return null;
    final volume = int.parse(volMatch.group(1)!);

    final muteResult = Process.runSync('pactl', [
      'get-sink-mute',
      '@DEFAULT_SINK@',
    ], runInShell: true);
    final muted =
        muteResult.exitCode == 0 &&
        (muteResult.stdout as String).contains('Mute: yes');
    return (volume, muted);
  }

  (int, bool)? _runAmixer() {
    final result = Process.runSync('amixer', [
      'get',
      'Master',
    ], runInShell: true);
    if (result.exitCode != 0) return null;
    final out = result.stdout as String;
    final volMatch = RegExp(r'\[(\d+)%\]').firstMatch(out);
    if (volMatch == null) return null;
    final volume = int.parse(volMatch.group(1)!);
    final muted = out.contains('[off]');
    return (volume, muted);
  }

  @override
  bool get hasClick => true;

  /// Wheel over the module steps the output volume (±[scroll-step]%).
  @override
  void onScroll(double delta) {
    if (delta == 0) return;
    if (onScrollUpCmd.isNotEmpty && delta < 0) {
      runBarCommand(onScrollUpCmd);
      return;
    }
    if (onScrollDownCmd.isNotEmpty && delta > 0) {
      runBarCommand(onScrollDownCmd);
      return;
    }
    final step = delta < 0 ? '+$_scrollStep%' : '-$_scrollStep%';
    Process.run('pactl', [
      'set-sink-volume',
      '@DEFAULT_SINK@',
      step,
    ], runInShell: false);
    Process.run('pactl', [
      'set-sink-mute',
      '@DEFAULT_SINK@',
      '0',
    ], runInShell: false);
    update();
  }

  @override
  void onClick(double x, double y, {int button = 0x110}) {
    if (onClickCmd.isNotEmpty) {
      Process.runSync(onClickCmd, [], runInShell: true);
      return;
    }
    // Simple toggle mute on click
    final arg = _muted ? '0' : '1';
    Process.runSync('pactl', [
      'set-sink-mute',
      '@DEFAULT_SINK@',
      arg,
    ], runInShell: true);
    update();
  }
}
