import 'dart:convert';
import 'dart:typed_data';
import 'package:wayland/wayland.dart';

class WaylandMessage {
  final int objectId;
  final int opcode;
  final List<dynamic> arguments;
  final List<WaylandType> argTypes;

  WaylandMessage(this.objectId, this.opcode, this.arguments, this.argTypes) {
    if (arguments.length != argTypes.length) {
      throw ArgumentError('Arguments and argument types must have the same length');
    }
  }

  Uint8List serialize() {
    final buffer = ByteData(calculateSize());
    int offset = 0;

    // Object ID
    buffer.setUint32(offset, objectId, Endian.little);
    print('Serialized objectId: $objectId at offset $offset');
    offset += 4;

    // Size and opcode
    final size = calculateSize();
    buffer.setUint32(offset, (size << 16) | opcode, Endian.little);
    print('Serialized size+opcode: ${(size << 16) | opcode} at offset $offset');
    offset += 4;

    for (var i = 0; i < arguments.length; i++) {
      final arg = arguments[i];
      final type = argTypes[i];

      switch (type) {
        case WaylandType.int:
          buffer.setInt32(offset, arg as int, Endian.little);
          offset += 4;
          break;
        case WaylandType.uint:
          buffer.setUint32(offset, arg as int, Endian.little);
          offset += 4;
          break;
        case WaylandType.object:
        case WaylandType.newId:
        case WaylandType.enumeration:
          if (arg is! int && arg is! Proxy) {
            throw ArgumentError('Expected int or Proxy for type $type, got ${arg.runtimeType}');
          }
          if (arg is Proxy) {
            buffer.setInt32(offset, arg.objectId, Endian.little);
            print('Serialized Proxy objectId: ${arg.objectId} at offset $offset');
          } else {
            buffer.setInt32(offset, arg as int, Endian.little);
            print('Serialized int: ${arg as int} at offset $offset');
          }
          offset += 4;
          break;
        case WaylandType.fixed:
          if (arg is! double) {
            throw ArgumentError('Expected double for fixed type, got ${arg.runtimeType}');
          }
          buffer.setInt32(offset, (arg * 256).round(), Endian.little);
          print('Serialized fixed: ${(arg * 256).round()} at offset $offset');
          offset += 4;
          break;
        case WaylandType.string:
          final stringBytes = utf8.encode(arg as String);
          buffer.setUint32(offset, stringBytes.length + 1, Endian.little); // +1 for null terminator
          offset += 4;
          for (var i = 0; i < stringBytes.length; i++) {
            buffer.setUint8(offset + i, stringBytes[i]);
          }
          buffer.setUint8(offset + stringBytes.length, 0); // null terminator
          offset += stringBytes.length + 1;
          while (offset % 4 != 0) {
            buffer.setUint8(offset, 0);
            offset++;
          }
          break;
        case WaylandType.array:
          if (arg is! Uint8List) {
            throw ArgumentError('Expected Uint8List for array type, got ${arg.runtimeType}');
          }
          final arrayBytes = arg;
          buffer.setUint32(offset, arrayBytes.length, Endian.little);
          print('Serialized array length: ${arrayBytes.length} at offset $offset');
          offset += 4;
          for (var j = 0; j < arrayBytes.length; j++) {
            buffer.setUint8(offset + j, arrayBytes[j]);
          }
          offset += arrayBytes.length;
          final padding = (4 - (arrayBytes.length % 4)) % 4;
          for (var j = 0; j < padding; j++) {
            buffer.setUint8(offset + j, 0);
          }
          print('Serialized array: $arrayBytes with padding $padding at offset $offset');
          offset += padding;
          break;
        case WaylandType.fd:
          print('Warning: File descriptor serialization not implemented');
          break;
      }
    }

    return buffer.buffer.asUint8List();
  }

  int calculateSize() {
    int size = 8; // Initial size for objectId and size+opcode
    print('Initial size: $size');
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
          print('Adding 4 bytes for type $type, new size: $size');
          break;
        case WaylandType.string:
          final stringBytes = utf8.encode(arg as String);
          size += 4 + stringBytes.length; // 4 for length, then string data
          while (size % 4 != 0) {
            size++; // Padding
          }
          break;
        case WaylandType.array:
          final arraySize = (arg as Uint8List).length;
          final paddedSize = (arraySize + 3) & ~3;  // Align to 4-byte boundary
          size += 4 + paddedSize;  // 4 bytes for the length + padded array size
          print('Adding ${4 + paddedSize} bytes for array, new size: $size');
          break;
        case WaylandType.fd:
          print('Warning: File descriptor size calculation not implemented');
          break;
      }
    }
    print('Final calculated size: $size');
    return size;
  }
}

(int, int, Uint8List) parseMessage(Uint8List data) {
  if (data.length < 8) {
    throw FormatException('Message data too short');
  }
  final senderID = uint32(data.sublist(0, 4), Endian.little);
  final opcodeAndSize = uint32(data.sublist(4, 8), Endian.little);
  final opcode = opcodeAndSize & 0xffff;
  final size = opcodeAndSize >> 16;

  if (data.length < size) {
    throw FormatException('Message data shorter than specified size');
  }

  final msgSize = size - 8;
  final msg = data.sublist(8, 8 + msgSize);

  return (senderID, opcode, msg);
}

int uint32(Uint8List src, Endian endian) {
  final byteData = ByteData.sublistView(src);
  return byteData.getUint32(0, endian);
}
