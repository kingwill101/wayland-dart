import 'dart:convert';
import 'dart:typed_data';

import 'package:wayland/wayland.dart';

(int, int, Uint8List) parseMessage(Uint8List data) {
  if (data.length < 8) {
    throw FormatException('Message data too short');
  }
  final objectId = uint32(data.sublist(0, 4));
  final opcodeAndSize = uint32(data.sublist(4, 8));
  final opcode = opcodeAndSize & 0xffff;
  final size = opcodeAndSize >> 16;

  if (data.length < size) {
    throw FormatException('Message data shorter than specified size');
  }

  final msgSize = size - 8;
  final arguments = data.sublist(8, 8 + msgSize);

  // logLn(
  //     'Parsed message: objectId: $objectId, opcode: $opcode, arguments: $arguments');

  return (objectId, opcode, arguments);
}

int uint32(Uint8List src, [Endian endian = Endian.little]) {
  final byteData = ByteData.sublistView(src);
  return byteData.getUint32(0, endian);
}

int calculateSize(
  List<WaylandType> argTypes,
  List<dynamic> arguments,
) {
  int size = 8; // Initial size for objectId and size+opcode
  // logLn('Initial size: $size');
  for (var i = 0; i < arguments.length; i++) {
    final arg = arguments[i];
    final type = argTypes[i];
    switch (type) {
      case WaylandType.int:
      case WaylandType.uint:
      case WaylandType.fixed:
      case WaylandType.object:
      case WaylandType.newId:
      case WaylandType.enumeration:
        size += 4;
        // logLn('Adding 4 bytes for type $type, new size: $size');
        break;
      case WaylandType.string:
        final stringBytes = utf8.encode(arg as String);
        size += 4 + stringBytes.length + 1; // 4 for length, then string data
        while (size % 4 != 0) {
          size++; // Padding
        }
        break;
      case WaylandType.array:
        final arraySize = (arg as Uint8List).length;
        final paddedSize = (arraySize + 3) & ~3; // Align to 4-byte boundary
        size += 4 + paddedSize; // 4 bytes for the length + padded array size
        // logLn('Adding ${4 + paddedSize} bytes for array, new size: $size');
        break;
      case WaylandType.fd:
        // logLn('Warning: File descriptor size calculation not implemented');
        break;
    }
  }
  return size;
}
