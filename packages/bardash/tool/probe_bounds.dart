import 'package:window_toolkit/window_toolkit.dart';

void main() {
  FontDatabase.instance.useSkiaEngine();
  final pairs = [
    ('Hack Nerd Font', '\uf013'),
    ('Hack Nerd Font', '\uf269'),
    ('Noto Color Emoji', '🔊'),
    ('Noto Color Emoji', '🔋'),
    ('sans', 'Hg'),
    ('sans', '64%'),
    ('sans', '/ M 34.8%'),
  ];
  for (final (fam, text) in pairs) {
    // via painter path
    // Use SkiaTextEngine through FontDatabase metrics boundingRect
    final f = Font(family: fam, pixelSize: 14);
    final m = FontDatabase.instance.metrics(f);
    final b = m.boundingRect(text);
    final a = m.horizontalAdvance(text);
    print('"$text" @$fam adv=${a.toStringAsFixed(2)} bounds L=${b.left.toStringAsFixed(2)} T=${b.top.toStringAsFixed(2)} R=${b.right.toStringAsFixed(2)} B=${b.bottom.toStringAsFixed(2)} H=${b.height.toStringAsFixed(2)}');
    final origin = TextLayout.drawOriginForBounds(0, 30, b);
    print('  originY=$origin ink ${origin+b.top}..${origin+b.bottom}');
  }
}
