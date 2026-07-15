import 'package:window_toolkit/window_toolkit.dart';

void main() {
  FontDatabase.instance.useSkiaEngine();
  FontDatabase.instance.setRoleFamily(FontRole.ui, 'sans');
  final font = Font.ui(pixelSize: 13);
  final m = FontDatabase.instance.metrics(font);
  print('ascent=${m.ascent} descent=${m.descent} leading=${m.leading} height=${m.height}');
  print('lineH=${TextLayout.lineHeightOf(m)}');
  const barH = 30.0;
  final b1 = TextLayout.baselineInBox(0, barH, ascent: m.ascent, descent: m.descent);
  print('baselineInBox=$b1');
  // ink range if ascent positive above baseline
  print('ink top=${b1 - m.ascent} bottom=${b1 + m.descent} mid=${(b1 - m.ascent + b1 + m.descent)/2}');
  final bounds = m.boundingRect('Apps');
  print('bounds Apps LTRB=${bounds.left},${bounds.top},${bounds.right},${bounds.bottom} h=${bounds.height}');
  final b2 = TextLayout.baselineForBounds(0, barH, bounds);
  print('baselineForBounds=$b2 ink mid should be 15');
  final layout = TextLayout.layoutInRect(
    'Apps',
    const Rect.fromLTWH(0, 0, 100, 30),
    font: font,
    option: TextOption.leftCenter,
  );
  print('layoutInRect baseline=${layout.baseline.dy}');
}
