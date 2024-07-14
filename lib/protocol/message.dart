import 'dart:typed_data';
import 'dart:convert';
import 'package:wayland/protocol/type.dart';
import 'package:wayland/wayland.dart';

class WaylandMessage {
  final int objectId;
  final int opcode;
  final List<dynamic> arguments;
  final List<WaylandType> argTypes;

  WaylandMessage(this.objectId, this.opcode, this.arguments, this.argTypes);

  Uint8List serialize() {
    final buffer = ByteData(calculateSize());
    int offset = 0;

    buffer.setUint32(offset, objectId, Endian.host);
    offset += 4;

    final size = buffer.lengthInBytes ~/ 4;
    buffer.setUint32(offset, (size << 16) | opcode, Endian.host);
    offset += 4;

    for (var i = 0; i < arguments.length; i++) {
      final arg = arguments[i];
      final type = argTypes[i];

      switch (type) {
        case WaylandType.int:
        case WaylandType.uint:
        case WaylandType.object:
        case WaylandType.newId:
        case WaylandType.enumeration:
          if(arg is Proxy){
            buffer.setInt32(offset, arg.id, Endian.host);
          } else {
            buffer.setInt32(offset, arg as int, Endian.host);
          }
          offset += 4;
          break;
        case WaylandType.fixed:
          buffer.setInt32(offset, (arg * 256).round(), Endian.host);
          offset += 4;
          break;
        case WaylandType.string:
          final stringBytes = utf8.encode(arg as String);
          buffer.setUint32(offset, stringBytes.length, Endian.host);
          offset += 4;
          for (var i = 0; i < stringBytes.length; i++) {
            buffer.setUint8(offset + i, stringBytes[i]);
          }
          offset += (stringBytes.length + 3) & ~3;
          break;
        case WaylandType.array:
          final arrayBytes = arg as Uint8List;
          buffer.setUint32(offset, arrayBytes.length, Endian.host);
          offset += 4;
          for (var i = 0; i < arrayBytes.length; i++) {
            buffer.setUint8(offset + i, arrayBytes[i]);
          }
          offset += (arrayBytes.length + 3) & ~3;
          break;
        case WaylandType.fd:
          break;
      }
    }

    return buffer.buffer.asUint8List();
  }

  static WaylandMessage deserialize(Uint8List data) {
    final buffer = ByteData.sublistView(data);
    int offset = 0;

    if (buffer.lengthInBytes < 8) {
      throw RangeError(
          'Data length is too short to contain a valid Wayland message');
    }

    final objectId = buffer.getUint32(offset, Endian.host);
    offset += 4;

    final sizeAndOpcode = buffer.getUint32(offset, Endian.host);
    final size = sizeAndOpcode >> 16;
    final opcode = sizeAndOpcode & 0xFFFF;
    offset += 4;

    if (buffer.lengthInBytes < size * 4) {
      throw RangeError(
          'Data length is too short to contain the specified message size');
    }

    final arguments = <dynamic>[];
    final argTypes = <WaylandType>[];

    while (offset < size * 4) {
      final type = WaylandType.values[buffer.getUint32(offset, Endian.host)];
      offset += 4;

      switch (type) {
        case WaylandType.int:
        case WaylandType.uint:
        case WaylandType.object:
        case WaylandType.newId:
        case WaylandType.enumeration:
          arguments.add(buffer.getInt32(offset, Endian.host));
          offset += 4;
          break;
        case WaylandType.fixed:
          arguments.add(buffer.getInt32(offset, Endian.host) / 256.0);
          offset += 4;
          break;
        case WaylandType.string:
          final length = buffer.getUint32(offset, Endian.host);
          offset += 4;
          arguments.add(utf8.decode(data.sublist(offset, offset + length)));
          offset += (length + 3) & ~3;
          break;
        case WaylandType.array:
          final length = buffer.getUint32(offset, Endian.host);
          offset += 4;
          arguments.add(data.sublist(offset, offset + length));
          offset += (length + 3) & ~3;
          break;
        case WaylandType.fd:
          // Handle file descriptors separately
          break;
      }

      argTypes.add(type);
    }

    return WaylandMessage(objectId, opcode, arguments, argTypes);
  }

  int calculateSize() {
    int size = 8;
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
          break;
        case WaylandType.string:
          size += 4 + ((utf8.encode(arg as String).length + 3) & ~3);
          break;
        case WaylandType.array:
          size += 4 + ((arg as Uint8List).length + 3) & ~3;
          break;
        case WaylandType.fd:
          break;
      }
    }
    return size;
  }
}

(int, int, Uint8List) parseMessage(Uint8List data) {
  // Implement your message parsing logic here
  // For example, extract senderID, opcode, fd, and msg
  final senderID = uint32(data.sublist(0, 4));
  final opcodeAndSize = uint32(data.sublist(4, 8));
  final opcode = opcodeAndSize & 0xffff;
  final size = opcodeAndSize >> 16;

  final msgSize = size - 8;
  final msg = data.sublist(8, 8 + msgSize);

  return (
    senderID,
    opcode,
    msg,
  );
}

int uint32(Uint8List src) {
  final byteData = ByteData.sublistView(src);
  return byteData.getUint32(0, Endian.little);
}
