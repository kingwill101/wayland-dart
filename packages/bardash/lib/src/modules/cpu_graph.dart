import 'dart:io';

import 'package:window_toolkit/window_toolkit.dart';

import 'module.dart';

/// CPU usage sparkline graph.
///
/// Renders a small line graph of recent CPU usage alongside a percentage
/// label. The graph scrolls left as new samples arrive.
///
/// Format placeholders:
///   {usage}    – current CPU usage percent
///   {icon}     – temperature icon
///
/// Config keys:
///   format         – text format (default: "{usage}%")
///   interval       – refresh in seconds (default: 1)
///   graph-width    – pixel width of the sparkline (default: 30)
///   graph-height   – pixel height of the sparkline (default: 14)
///   samples        – number of samples to keep (default: 30)
///   color          – line color as hex (default: "88c0d0")
///   on-click       – command on click
class CpuGraphModule extends BarModule {
  @override
  String get name => 'cpu/graph';

  @override
  bool get showsGraphics => true;

  final List<double> _history = [];
  int _prevUser = 0,
      _prevNice = 0,
      _prevSystem = 0,
      _prevIdle = 0,
      _prevIowait = 0;
  double _currentUsage = 0.0;
  int _graphWidth = 30;
  int _graphHeight = 14;
  int _maxSamples = 30;
  Color _lineColor = const Color(0x88, 0xc0, 0xd0);
  late final TextRuns _textWidget;
  late final Sparkline _graphWidget;

  @override
  void init(Map<String, String> config) {
    super.init(config);
    format = resolveFormat(config, '{usage}%', '');
    interval = parseInt(config, 'interval', 1);
    _graphWidth = parseInt(config, 'graph-width', 30);
    _graphHeight = parseInt(config, 'graph-height', 14);
    _maxSamples = parseInt(config, 'samples', 30);
    if (config.containsKey('color')) {
      _lineColor = parseColor(config['color']!);
    }
    _textWidget = TextRuns('');
    _graphWidget = Sparkline(
      values: _history,
      width: _graphWidth,
      height: _graphHeight,
      lineColor: _lineColor,
      minValue: 0,
    );
    widget = HBox(spacing: 4, children: [_textWidget, _graphWidget]);
  }

  void _syncWidget() {
    _textWidget.text = output;
    _graphWidget.values = _history;
    requestRepaint?.call();
  }

  @override
  void update() {
    try {
      final line = File('/proc/stat').readAsStringSync().split('\n')[0];
      final parts = line.split(RegExp(r'\s+'));
      if (parts.length < 5 || parts[0] != 'cpu') {
        output = 'ERR';
        _syncWidget();
        return;
      }
      final user = int.tryParse(parts[1]) ?? 0;
      final nice = int.tryParse(parts[2]) ?? 0;
      final system = int.tryParse(parts[3]) ?? 0;
      final idle = int.tryParse(parts[4]) ?? 0;
      final iowait = parts.length > 5 ? int.tryParse(parts[5]) ?? 0 : 0;

      if (_prevUser != 0) {
        final totalDelta =
            (user - _prevUser) +
            (nice - _prevNice) +
            (system - _prevSystem) +
            (idle - _prevIdle) +
            (iowait - _prevIowait);
        final idleDelta = idle - _prevIdle;
        if (totalDelta > 0) {
          _currentUsage = (totalDelta - idleDelta) / totalDelta * 100;
          _history.add(_currentUsage);
          if (_history.length > _maxSamples) {
            _history.removeAt(0);
          }
        }
      }

      _prevUser = user;
      _prevNice = nice;
      _prevSystem = system;
      _prevIdle = idle;
      _prevIowait = iowait;

      output = format.replaceAll('{usage}', _currentUsage.toStringAsFixed(1));
      _syncWidget();
    } catch (_) {
      output = 'ERR';
      _syncWidget();
    }
  }
}
