/// Minimal RGBA → PNG encoder (no external deps).
library;

import 'dart:convert' show ascii;
import 'dart:io' show ZLibCodec, ZLibOption;
import 'dart:typed_data';

/// Encode [rgba] (length `w*h*4`, R,G,B,A) as a PNG byte stream.
Uint8List encodeRgbaPng(int w, int h, List<int> rgba) {
  assert(rgba.length >= w * h * 4);

  final raw = BytesBuilder(copy: false);
  final src = rgba is Uint8List ? rgba : Uint8List.fromList(rgba);
  for (var y = 0; y < h; y++) {
    raw.addByte(0); // filter: None
    final start = y * w * 4;
    raw.add(Uint8List.sublistView(src, start, start + w * 4));
  }
  // PNG IDAT requires zlib-wrapped deflate (RFC 1950), not raw deflate.
  final compressed = ZLibCodec(level: ZLibOption.defaultLevel)
      .encode(raw.takeBytes());

  final out = BytesBuilder(copy: false);
  out.add(const [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]);
  out.add(_chunk('IHDR', _ihdr(w, h)));
  out.add(_chunk('IDAT', compressed));
  out.add(_chunk('IEND', const <int>[]));
  return out.takeBytes();
}

Uint8List _ihdr(int w, int h) {
  final b = ByteData(13);
  b.setUint32(0, w);
  b.setUint32(4, h);
  b.setUint8(8, 8); // bit depth
  b.setUint8(9, 6); // RGBA
  b.setUint8(10, 0);
  b.setUint8(11, 0);
  b.setUint8(12, 0);
  return b.buffer.asUint8List();
}

Uint8List _chunk(String type, List<int> data) {
  final typeBytes = ascii.encode(type);
  final len = ByteData(4)..setUint32(0, data.length);
  final body = BytesBuilder(copy: false)
    ..add(typeBytes)
    ..add(data);
  final bodyBytes = body.takeBytes();
  final crc = ByteData(4)..setUint32(0, _crc32(bodyBytes));
  return (BytesBuilder(copy: false)
        ..add(len.buffer.asUint8List())
        ..add(bodyBytes)
        ..add(crc.buffer.asUint8List()))
      .takeBytes();
}

/// PNG CRC-32 (ISO 3309), always in 32-bit range.
int _crc32(List<int> data) {
  var c = 0xffffffff;
  for (final byte in data) {
    c ^= byte & 0xff;
    for (var i = 0; i < 8; i++) {
      if ((c & 1) != 0) {
        c = 0xedb88320 ^ (c >> 1);
      } else {
        c >>= 1;
      }
      c &= 0xffffffff;
    }
  }
  return (c ^ 0xffffffff) & 0xffffffff;
}
