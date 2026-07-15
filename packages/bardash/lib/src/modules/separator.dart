import 'package:window_toolkit/window_toolkit.dart';

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
    return painter.measureText(output, size: 12).width;
  }

  @override
  double draw(Painter painter, double x, double y) {
    painter.drawText(
      output,
      Offset(x, y + 1),
      color: _color,
      size: 12,
    );
    return painter.measureText(output, size: 12).width;
  }
}
