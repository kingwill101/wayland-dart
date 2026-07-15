import 'package:window_toolkit/src/painter/skia_text_engine.dart';

void main() {
  final engine = SkiaTextEngine.shared;
  for (final family in ['sans', 'Noto Sans', 'Hack Nerd Font']) {
    final adv = engine.measureTextAdvance('Apps', size: 13, fontFamily: family);
    final b = engine.measureTextBounds('Apps', size: 13, fontFamily: family);
    final s = engine.measureText('Apps', size: 13, fontFamily: family);
    print(
      'family=$family advance=${adv.toStringAsFixed(2)} '
      'measure.w=${s.width.toStringAsFixed(2)} '
      'bounds=${b.left.toStringAsFixed(1)}..${b.right.toStringAsFixed(1)} '
      'b.w=${b.width.toStringAsFixed(2)}',
    );
  }
  for (final ch in ['\uf013', '\uf269', '\uf07b']) {
    final adv = engine.measureTextAdvance(ch, size: 13, fontFamily: 'Hack Nerd Font');
    print('icon U+${ch.runes.first.toRadixString(16)} advance=${adv.toStringAsFixed(2)}');
  }
}
