import 'dart:io';

import 'package:window_toolkit/window_toolkit.dart';

import '../command.dart';
import '../metrics.dart';
import 'module.dart';

class CustomModule extends BarModule {
  @override
  String get name => 'custom';

  String _exec = "echo 'hello'";
  Color _color = const Color(0xff, 0xff, 0xff);

  bool _static = false;

  @override
  void init(Map<String, String> config) {
    super.init(config);
    // Waybar-style static custom modules use `format` with no `exec`.
    if (config.containsKey('format') && !config.containsKey('exec')) {
      _static = true;
      format = config['format']!;
      output = format;
      interval = 0;
    } else {
      if (config.containsKey('exec')) {
        _exec = config['exec']!;
      }
      interval = parseInt(config, 'interval', 5);
    }
    if (config.containsKey('color')) {
      _color = parseColor(config['color']!);
    }
    if (config.containsKey('tooltip-format')) {
      tooltip = config['tooltip-format']!;
      tooltipFormat = config['tooltip-format']!;
    }
  }

  @override
  void update() {
    if (_static) {
      output = format;
      if (tooltipFormat.isNotEmpty) tooltip = tooltipFormat;
      return;
    }
    try {
      final parts = _exec.split(' ');
      final cmd = parts[0];
      final args = parts.length > 1 ? parts.sublist(1) : <String>[];
      final result = Process.runSync(cmd, args, runInShell: true);
      if (result.exitCode != 0) {
        output = 'ERR';
        return;
      }
      final out = (result.stdout as String).trim();
      output = out.isEmpty ? '...' : out;
      tooltip = tooltipFormat.isNotEmpty ? tooltipFormat : output;
    } catch (_) {
      output = 'ERR';
    }
  }

  @override
  void onClick(double x, double y, {int button = 0x110}) {
    final cmd = button == 0x111 ? onClickRightCmd : onClickCmd;
    runBarCommand(cmd);
  }

  @override
  double measure(Painter painter) {
    final m = BarMetrics.current;
    // Short icon labels (FontAwesome / emoji) get a fixed slot so bad
    // glyph metrics don't create huge gaps in groups.
    if (m.isIconOutput(output)) return m.iconContentWidth();
    final w = painter.measureTextRuns(
      output,
      textFont: Font.ui(pixelSize: m.fontSize),
      iconFont: Font.icon(pixelSize: m.iconFontSize),
    );
    return m.textContentWidth(w, min: 8);
  }

  @override
  double draw(Painter painter, double x, double y) {
    final m = BarMetrics.current;
    if (m.isIconOutput(output)) {
      // Icon role → FontDatabase icon family (config icon_font_family).
      painter.drawTextRuns(
        output,
        Offset(x, y),
        textFont: Font.ui(pixelSize: m.fontSize),
        iconFont: Font.icon(pixelSize: m.iconFontSize),
        color: _color,
      );
      return m.iconContentWidth();
    }
    painter.drawTextRuns(
      output,
      Offset(x, y),
      textFont: Font.ui(pixelSize: m.fontSize),
      iconFont: Font.icon(pixelSize: m.iconFontSize),
      color: _color,
    );
    final w = painter.measureTextRuns(
      output,
      textFont: Font.ui(pixelSize: m.fontSize),
      iconFont: Font.icon(pixelSize: m.iconFontSize),
    );
    return m.textContentWidth(w, min: 8);
  }
}
