import 'dart:io';

import 'package:window_toolkit/window_toolkit.dart';

import 'module.dart';

/// Custom command with sparkline graph.
///
/// Runs a shell command every interval, parses a numeric value from its
/// output, and renders a sparkline history alongside the current value.
///
/// The command's stdout should contain a number (integer or float). The
/// value can be anywhere in the output and is extracted via an optional
/// regex pattern.
///
/// Format placeholders:
///   {value}    – current numeric value (formatted)
///   {min}      – minimum value in history
///   {max}      – maximum value in history
///   {avg}      – average value in history
///
/// Config keys:
///   exec            – command to run (required)
///   format          – display format (default: "{value}")
///   interval        – refresh in seconds (default: 5)
///   graph-width     – pixel width (default: 30)
///   graph-height    – pixel height (default: 14)
///   samples         – history length (default: 30)
///   pattern         – regex to extract number (default: "([\\d.]+)")
///   color           – line color hex (default: "a3be8c")
///   min             – fixed Y-axis minimum (default: auto)
///   max             – fixed Y-axis maximum (default: auto)
///   on-click        – command on click
class CustomGraphModule extends BarModule {
  @override
  String get name => 'custom/graph';

  @override
  bool get showsGraphics => true;

  String _exec = "echo '50'";
  final List<double> _history = [];
  double _currentValue = 0;
  int _graphWidth = 30;
  int _graphHeight = 14;
  int _maxSamples = 30;
  String _pattern = r'([\d.]+)';
  double? _fixedMin;
  double? _fixedMax;
  Color _lineColor = const Color(0xa3, 0xbe, 0x8c);
  late final TextRuns _textWidget;
  late final Sparkline _graphWidget;

  @override
  void init(Map<String, String> config) {
    super.init(config);
    format = resolveFormat(config, '{value}', '');
    interval = parseInt(config, 'interval', 5);
    _graphWidth = parseInt(config, 'graph-width', 30);
    _graphHeight = parseInt(config, 'graph-height', 14);
    _maxSamples = parseInt(config, 'samples', 30);
    if (config.containsKey('exec')) _exec = config['exec']!;
    if (config.containsKey('pattern')) _pattern = config['pattern']!;
    if (config.containsKey('min')) _fixedMin = double.tryParse(config['min']!);
    if (config.containsKey('max')) _fixedMax = double.tryParse(config['max']!);
    if (config.containsKey('color')) {
      _lineColor = parseColor(config['color']!);
    }
    _textWidget = TextRuns('');
    _graphWidget = Sparkline(
      values: _history,
      width: _graphWidth,
      height: _graphHeight,
      lineColor: _lineColor,
      minValue: _fixedMin,
      maxValue: _fixedMax,
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
      final result = Process.runSync(_exec, [], runInShell: true);
      if (result.exitCode != 0) {
        output = 'ERR';
        _syncWidget();
        return;
      }
      final stdout = result.stdout as String;
      final match = RegExp(_pattern).firstMatch(stdout);
      if (match == null) {
        output = 'N/A';
        _syncWidget();
        return;
      }

      _currentValue = double.tryParse(match.group(1)!) ?? 0.0;
      _history.add(_currentValue);
      if (_history.length > _maxSamples) {
        _history.removeAt(0);
      }

      if (_history.isEmpty) {
        output = format.replaceAll('{value}', '0');
        _syncWidget();
        return;
      }

      final min = _history.reduce((a, b) => a < b ? a : b);
      final max = _history.reduce((a, b) => a > b ? a : b);
      final avg = _history.reduce((a, b) => a + b) / _history.length;

      output = format
          .replaceAll('{value}', _currentValue.toStringAsFixed(1))
          .replaceAll('{min}', min.toStringAsFixed(1))
          .replaceAll('{max}', max.toStringAsFixed(1))
          .replaceAll('{avg}', avg.toStringAsFixed(1));
      _syncWidget();
    } catch (_) {
      output = 'ERR';
      _syncWidget();
    }
  }
}
