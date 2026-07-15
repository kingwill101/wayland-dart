import 'package:window_toolkit/src/painter/skia_text_engine.dart';
import 'package:window_toolkit/window_toolkit.dart';

void main() {
  final e = SkiaTextEngine.shared;
  final b = e.measureTextBounds('Apps', size: 13, fontFamily: 'sans');
  final a = e.measureTextAdvance('Apps', size: 13, fontFamily: 'sans');
  print('Apps advance=$a bounds LTRB=${b.left},${b.top},${b.right},${b.bottom} h=${b.height}');
  final origin = TextLayout.drawOriginForBounds(0, 30, b);
  print('drawOrigin for 30px bar=$origin');
  print('ink will be ${origin+b.top} .. ${origin+b.bottom} mid=${origin+(b.top+b.bottom)/2}');
}
