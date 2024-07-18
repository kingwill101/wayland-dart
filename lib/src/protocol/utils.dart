import 'dart:convert';
import 'dart:typed_data';

String getString(Uint8List data, int offset) {
  final length = ByteData.view(data.buffer).getUint32(offset, Endian.little);
  offset += 4;
  final stringBytes = data.sublist(offset, offset + (length - 1)); // -1 to remove null terminator
  return utf8.decode(stringBytes);
}

  Uint8List getArray(Uint8List data, int offset) {
    final length = ByteData.view(data.buffer).getUint32(offset, Endian.host);
    return data.sublist(offset + 4, offset + 4 + length);
  }

double fixedToDouble(int fixed) {
  
  return fixed / 256.0;
}

int doubleToFixed(double value) {
  return (value * (1 << 16)).toInt();
}

