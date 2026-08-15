import 'package:window_toolkit/window_toolkit.dart';

import '../metrics.dart';
import 'module.dart';

/// Visual divider between modules (waybar-style custom separator).
///
/// Config:
///   format / text  – glyph to show (default "·")
///   color          – hex color
///   padding        – horizontal padding (default 4)
class SeparatorModule extends BarModule {
  @override
  String get name => 'separator';

  Color _color = const Color(120, 120, 120);
  String _text = '·';

  @override
  void init(Map<String, String> config) {
    // Separators are narrow by default (no extra pad).
    final withDefaults = Map<String, String>.from(config);
    withDefaults.putIfAbsent('padding', () => '0');
    super.init(withDefaults);
    interval = 0;
    _text = config['format'] ?? config['text'] ?? '·';
    if (config.containsKey('color')) {
      _color = parseColor(config['color']!);
    }
    output = _text;
  }

  @override
  void update() {
    output = _text;
  }

  @override
  double measure(Painter painter) {
    final font = Font.ui(pixelSize: BarMetrics.current.fontSize);
    return painter.measureTextFont(output, font);
  }

  @override
  double draw(Painter painter, double x, double y) {
    final font = Font.ui(pixelSize: BarMetrics.current.fontSize);
    painter.drawTextFont(
      output,
      Offset(x, y + 1),
      color: cssForeground ?? _color,
      font: font,
    );
    return painter.measureTextFont(output, font);
  }
}
