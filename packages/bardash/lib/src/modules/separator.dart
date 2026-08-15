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

  String _text = '·';

  @override
  void init(Map<String, String> config) {
    // Separators are narrow by default (no extra pad).
    final withDefaults = Map<String, String>.from(config);
    withDefaults.putIfAbsent('padding', () => '0');
    super.init(withDefaults);
    interval = 0;
    _text = config['format'] ?? config['text'] ?? '·';
    output = _text;
  }

  @override
  void update() {
    output = _text;
  }
}
