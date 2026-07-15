import 'dart:io';
import 'dart:typed_data';
import '../lib/src/png_encode.dart';
void main() {
  final rgba = Uint8List(16 * 16 * 4);
  for (var i = 0; i < 16 * 16; i++) {
    rgba[i * 4] = 255;
    rgba[i * 4 + 1] = 0;
    rgba[i * 4 + 2] = 0;
    rgba[i * 4 + 3] = 255;
  }
  final png = encodeRgbaPng(16, 16, rgba);
  File('/tmp/test_bardash.png').writeAsBytesSync(png);
  print('png ${png.length} bytes magic=${png.sublist(0, 8)}');
}
