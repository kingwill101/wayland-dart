import 'dart:io';

import 'package:window_toolkit/window_toolkit.dart';

import '../command.dart';
import '../metrics.dart';
import 'module.dart';

/// Privacy indicators: camera / mic in use.
///
/// Avoids heavy `wpctl`/`pw-cli` sync polls. Uses:
/// - V4L2 `/sys/class/video4linux/*/device/power/runtime_status` or open handles
/// - PipeWire / Pulse via async `pactl list source-outputs` short parse
/// - Optional: `wpctl status` only if needed
///
/// Placeholders: `{camera}` `{mic}` `{icon}` `{icon-camera}` `{icon-mic}`
class PrivacyModule extends BarModule {
  @override
  String get name => 'privacy';

  bool _cameraActive = false;
  bool _micActive = false;
  bool _updating = false;
  String _lastOut = '';

  @override
  void init(Map<String, String> config) {
    super.init(config);
    format = resolveFormat(config, '{icon}', '');
    interval = parseInt(config, 'interval', 3);
  }

  @override
  void update() {
    if (_updating) return;
    _updating = true;
    _poll().whenComplete(() => _updating = false);
  }

  Future<void> _poll() async {
    try {
      _cameraActive = _checkCamera();
      _micActive = await _checkMicAsync();

      if (!_cameraActive && !_micActive) {
        output = '';
        tooltip = '';
        _maybeRepaint();
        return;
      }

      final cameraIcon = _cameraActive ? '📷' : '';
      final micIcon = _micActive ? '🎤' : '';
      final combined = [
        if (cameraIcon.isNotEmpty) cameraIcon,
        if (micIcon.isNotEmpty) micIcon,
      ].join(' ');

      output = format
          .replaceAll('{icon-camera}', cameraIcon)
          .replaceAll('{icon-mic}', micIcon)
          .replaceAll('{icon}', combined)
          .replaceAll('{camera}', _cameraActive ? 'on' : '')
          .replaceAll('{mic}', _micActive ? 'on' : '');

      tooltip = [
        if (_cameraActive) 'Camera in use',
        if (_micActive) 'Microphone in use',
      ].join('\n');
      _maybeRepaint();
    } catch (_) {
      output = '';
      _maybeRepaint();
    }
  }

  void _maybeRepaint() {
    if (output != _lastOut) {
      _lastOut = output;
      requestRepaint?.call();
    }
  }

  bool _checkCamera() {
    try {
      final dir = Directory('/sys/class/video4linux');
      if (!dir.existsSync()) return false;
      for (final entry in dir.listSync()) {
        // Active capture often holds the device node open.
        final name = entry.uri.pathSegments.last;
        final devNode = File('/dev/$name');
        if (!devNode.existsSync()) continue;
        // runtime_status "active" is a weak signal; /proc fd scan is heavier.
        final status = File('${entry.path}/device/power/runtime_status');
        if (status.existsSync()) {
          final s = status.readAsStringSync().trim();
          if (s == 'active') return true;
        }
      }
      // Fallback: anyone holding /dev/video*
      return _procHolds(RegExp(r'/dev/video\d+'));
    } catch (_) {
      return false;
    }
  }

  Future<bool> _checkMicAsync() async {
    try {
      final pactl = await Process.run(
        'pactl',
        ['list', 'source-outputs', 'short'],
        runInShell: false,
      );
      if (pactl.exitCode == 0) {
        final out = (pactl.stdout as String).trim();
        if (out.isNotEmpty) return true;
      }
    } catch (_) {}

    try {
      final r = await Process.run(
        'pw-cli',
        ['ls', 'Node'],
        runInShell: false,
      );
      if (r.exitCode == 0) {
        final out = r.stdout as String;
        // Crude: look for Audio/Source with state running
        if (out.contains('Audio/Source') &&
            (out.contains('running') || out.contains('RUNNING'))) {
          return true;
        }
      }
    } catch (_) {}

    return _procHolds(RegExp(r'pipewire|pulse', caseSensitive: false)) &&
        false; // don't false-positive on pipewire itself
  }

  /// True if any process has an open fd matching [pattern] in its path.
  bool _procHolds(RegExp pattern) {
    try {
      final proc = Directory('/proc');
      for (final e in proc.listSync()) {
        final name = e.uri.pathSegments.last;
        if (int.tryParse(name) == null) continue;
        final fdDir = Directory('/proc/$name/fd');
        if (!fdDir.existsSync()) continue;
        try {
          for (final fd in fdDir.listSync(followLinks: false)) {
            try {
              final target = Link(fd.path).targetSync();
              if (pattern.hasMatch(target)) return true;
            } catch (_) {}
          }
        } catch (_) {}
      }
    } catch (_) {}
    return false;
  }

  @override
  double measure(Painter painter) {
    if (output.isEmpty) return 0;
    final m = BarMetrics.current;
    // Emoji icons: fixed slots + gap between camera/mic.
    final n = (_cameraActive ? 1 : 0) + (_micActive ? 1 : 0);
    if (n == 0) return 0;
    return n * m.iconContentWidth() +
        (n > 1 ? m.iconTextGap : 0);
  }

  @override
  double draw(Painter painter, double x, double y) {
    if (output.isEmpty) return 0;
    final m = BarMetrics.current;
    final emoji = Font(family: m.emojiFamily, pixelSize: m.fontSize);
    final gap = m.iconTextGap.toDouble();
    var cx = x;
    const color = Color(0xff, 0xcc, 0x00);
    if (_cameraActive) {
      final w = m.emojiLayoutWidth(painter.measureTextFont('📷', emoji));
      painter.drawTextFont('📷', Offset(cx, y), font: emoji, color: color);
      cx += w + (_micActive ? gap : 0);
    }
    if (_micActive) {
      final w = m.emojiLayoutWidth(painter.measureTextFont('🎤', emoji));
      painter.drawTextFont('🎤', Offset(cx, y), font: emoji, color: color);
      cx += w;
    }
    return cx - x;
  }

  @override
  void onClick(double x, double y, {int button = 0x110}) {
    if (onClickCmd.isNotEmpty) runBarCommand(onClickCmd);
  }
}
