import 'dart:convert';
import 'dart:typed_data';

String getString(Uint8List data, int offset) {
    final length = ByteData.view(data.buffer).getUint32(offset, Endian.host);
    return utf8.decode(data.sublist(offset + 4, offset + 4 + length));
  }

  Uint8List getArray(Uint8List data, int offset) {
    final length = ByteData.view(data.buffer).getUint32(offset, Endian.host);
    return data.sublist(offset + 4, offset + 4 + length);
  }

double fixedToDouble(int fixed) {
  return fixed / 256.0;
}