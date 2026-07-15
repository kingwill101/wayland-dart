import 'package:window_toolkit/src/painter/skia_text_engine.dart';

void main() {
  final e = SkiaTextEngine.shared;
  for (final t in ['Apps', 'Hg', '100%', '🔊']) {
    final b = e.measureTextBounds(t, size: 13, fontFamily: 'sans');
    final a = e.measureTextAdvance(t, size: 13, fontFamily: 'sans');
    print('$t advance=$a bounds LTRB=${b.left},${b.top},${b.right},${b.bottom} h=${b.height}');
  }
  // emoji font
  for (final t in ['🔊', '⚡', '🔋']) {
    final b = e.measureTextBounds(t, size: 13, fontFamily: 'Noto Color Emoji');
    final a = e.measureTextAdvance(t, size: 13, fontFamily: 'Noto Color Emoji');
    print('emoji $t advance=$a bounds LTRB=${b.left},${b.top},${b.right},${b.bottom}');
  }
}
