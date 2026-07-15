import 'dart:io';
import 'dart:math' as math;

import 'package:window_toolkit/window_toolkit.dart';

import '../metrics.dart';
import '../native/pipewire_query.dart';
import 'module.dart';

/// PipeWire / WirePlumber volume module.
///
/// Polls `wpctl` **asynchronously** so the bar event loop is not blocked by
/// `Process.runSync` (was ~7% of profile samples at interval 1s).
///
/// Placeholders: `{volume}`, `{icon}`, `{muted}`, `{format_source}`,
/// `{source_volume}`, `{source_icon}`, `{node_name}`.
class WireplumberModule extends BarModule {
  @override
  String get name => 'wireplumber';

  int _volume = 0;
  bool _muted = false;
  int _sourceVolume = 0;
  bool _sourceMuted = false;
  String _nodeName = '';
  String _formatSource = '{source_volume}% \u{f130}';
  String _formatSourceMuted = '\u{f131}';
  int _scrollStep = 5;

  bool _updating = false;
  String _lastOutput = '';

  @override
  void init(Map<String, String> config) {
    super.init(config);
    format = resolveFormat(config, '{icon} {volume}% {format_source}', '');
    _formatSource = config['format-source'] ?? '{source_volume}% \u{f130}';
    _formatSourceMuted = config['format-source-muted'] ?? '\u{f131}';
    _scrollStep = parseInt(config, 'scroll-step', 5).clamp(1, 25);
    // Default 2s — still responsive; avoids constant process spawn.
    interval = parseInt(config, 'interval', 2);
  }

  @override
  void update() {
    if (_updating) return;
    _updating = true;
    _pollAsync().whenComplete(() {
      _updating = false;
    });
  }

  Future<void> _pollAsync() async {
    await Future.wait([_updateSink(), _updateSource()]);
    _applyFormat();
    tooltip = resolveTooltip(
      'Vol $_volume%${_muted ? ' (muted)' : ''} · '
      'Mic $_sourceVolume%${_sourceMuted ? ' (muted)' : ''}',
      {
        'volume': '$_volume',
        'muted': _muted ? 'yes' : 'no',
        'source_volume': '$_sourceVolume',
        'node_name': _nodeName,
      },
    );
    if (output != _lastOutput) {
      _lastOutput = output;
      requestRepaint?.call();
    }
  }

  void _applyFormat() {
    final sinkIcon = _muted
        ? '🔇'
        : _volume == 0
            ? '🔈'
            : _volume < 50
                ? '🔉'
                : '🔊';
    final sourceIcon = _sourceMuted ? '🎤̸' : '🎤';
    final sourceSeg = (_sourceMuted ? _formatSourceMuted : _formatSource)
        .replaceAll('{source_volume}', '$_sourceVolume')
        .replaceAll('{source_icon}', sourceIcon);

    output = format
        .replaceAll('{volume}', '$_volume')
        .replaceAll('{icon}', sinkIcon)
        .replaceAll('{muted}', _muted ? 'yes' : 'no')
        .replaceAll('{node_name}', _nodeName)
        .replaceAll('{format_source}', sourceSeg)
        .replaceAll('{source_volume}', '$_sourceVolume')
        .replaceAll('{source_icon}', sourceIcon);
  }

  int _toPercent(double linear) {
    final p = math.pow(linear.clamp(0.0, 1.5), 1.0 / 3.0) * 100;
    return p.round().clamp(0, 150);
  }

  Future<void> _updateSink() async {
    try {
      final result = await Process.run(
        'wpctl',
        ['get-volume', '@DEFAULT_AUDIO_SINK@'],
        runInShell: false,
      );
      if (result.exitCode == 0) {
        final out = (result.stdout as String).trim();
        final volMatch = RegExp(r'Volume:\s+([\d.]+)').firstMatch(out);
        if (volMatch != null) {
          final linear = double.tryParse(volMatch.group(1)!) ?? 0.0;
          _muted = out.contains('[MUTED]');
          _volume = _toPercent(linear);
          return;
        }
      }
    } catch (_) {}

    try {
      final info = queryDefaultSink(timeoutSec: 1);
      if (info != null) {
        _nodeName = info.nodeName;
        _muted = info.muted;
        _volume = _toPercent(info.volume);
      }
    } catch (_) {}
  }

  Future<void> _updateSource() async {
    try {
      final result = await Process.run(
        'wpctl',
        ['get-volume', '@DEFAULT_AUDIO_SOURCE@'],
        runInShell: false,
      );
      if (result.exitCode != 0) return;
      final out = (result.stdout as String).trim();
      final volMatch = RegExp(r'Volume:\s+([\d.]+)').firstMatch(out);
      if (volMatch == null) return;
      final linear = double.tryParse(volMatch.group(1)!) ?? 0.0;
      _sourceMuted = out.contains('[MUTED]');
      _sourceVolume = _toPercent(linear);
    } catch (_) {}
  }

  Future<void> _runWpctl(List<String> args) async {
    try {
      await Process.run('wpctl', args, runInShell: false);
    } catch (_) {}
    await _pollAsync();
  }

  // Emoji icons use Noto Color Emoji (not FA/Nerd). Measuring with Nerd gave
  // ~8px advance while the fallback painted ~16px → text under the speaker.
  double get _fontSize => BarMetrics.current.fontSize;
  double get _iconTextGap => BarMetrics.current.iconTextGap.toDouble();

  Font get _uiFont => Font.icon(pixelSize: _fontSize);
  Font get _emojiFont => Font(
        family: BarMetrics.current.emojiFamily,
        pixelSize: _fontSize,
      );

  String get _sinkIcon => _muted
      ? '🔇'
      : _volume == 0
          ? '🔈'
          : _volume < 50
              ? '🔉'
              : '🔊';

  String get _sourceIcon => _sourceMuted ? '🎤̸' : '🎤';

  bool get _showMic =>
      format.contains('{format_source}') || format.contains('{source_icon}');

  /// Volume / source digits only (emoji stripped for layout).
  String get _textPart {
    final src = _sourceMuted
        ? _formatSourceMuted
            .replaceAll('{source_volume}', '$_sourceVolume')
            .replaceAll('{source_icon}', '')
        : _formatSource
            .replaceAll('{source_volume}', '$_sourceVolume')
            .replaceAll('{source_icon}', '');
    var s = format
        .replaceAll('{volume}', '$_volume')
        .replaceAll('{icon}', '')
        .replaceAll('{muted}', _muted ? 'yes' : 'no')
        .replaceAll('{node_name}', _nodeName)
        .replaceAll('{format_source}', src.trim())
        .replaceAll('{source_volume}', '$_sourceVolume')
        .replaceAll('{source_icon}', '');
    // Drop emoji / symbols left in format strings (e.g. literal 🎤).
    s = s.replaceAll(RegExp(r'[^\x09\x0A\x0D\x20-\x7E]+'), ' ');
    return s.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  double _emojiWidth(Painter painter, String icon) {
    final adv = painter.measureTextFont(icon, _emojiFont);
    return BarMetrics.current.emojiLayoutWidth(adv);
  }

  @override
  double measure(Painter painter) {
    final textW = painter.measureTextFont(_textPart, _uiFont);
    final sinkW = _emojiWidth(painter, _sinkIcon);
    final micW = _showMic ? _emojiWidth(painter, _sourceIcon) : 0.0;
    // [emoji][gap][text][gap][mic]
    return (sinkW +
            _iconTextGap +
            textW +
            (_showMic ? _iconTextGap + micW : 0))
        .clamp(8, 220);
  }

  @override
  double draw(Painter painter, double x, double y) {
    var cx = x;
    final sinkW = _emojiWidth(painter, _sinkIcon);
    painter.drawTextFont(_sinkIcon, Offset(cx, y), font: _emojiFont);
    // Advance by full emoji layout width + gap so text never sits under ink.
    cx += sinkW + _iconTextGap;
    final text = _textPart;
    painter.drawTextFont(text, Offset(cx, y), font: _uiFont);
    cx += painter.measureTextFont(text, _uiFont);
    if (_showMic) {
      cx += _iconTextGap;
      final micW = _emojiWidth(painter, _sourceIcon);
      painter.drawTextFont(_sourceIcon, Offset(cx, y), font: _emojiFont);
      cx += micW;
    }
    return (cx - x).clamp(8, 220);
  }

  @override
  bool get hasClick => true;

  @override
  void onClick(double x, double y, {int button = 0x110}) {
    if (onClickCmd.isNotEmpty) {
      Process.run(onClickCmd, [], runInShell: true);
      update();
      return;
    }
    _runWpctl(['set-mute', '@DEFAULT_AUDIO_SINK@', 'toggle']);
  }

  @override
  void onScroll(double delta) {
    if (delta == 0) return;
    if (onScrollUpCmd.isNotEmpty && delta < 0) {
      Process.run(onScrollUpCmd, [], runInShell: true);
      update();
      return;
    }
    if (onScrollDownCmd.isNotEmpty && delta > 0) {
      Process.run(onScrollDownCmd, [], runInShell: true);
      update();
      return;
    }
    final up = delta < 0;
    final sign = up ? '+' : '-';
    _runWpctl([
      'set-volume',
      '@DEFAULT_AUDIO_SINK@',
      '$sign$_scrollStep%',
      '-l',
      '1.5',
    ]);
  }
}
