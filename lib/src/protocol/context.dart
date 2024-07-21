import 'dart:async';
import 'dart:typed_data';

import 'package:wayland/src/protocol/connection.dart';
import 'package:wayland/wayland.dart';

class Context {
  late UnixSocket _socket;

  Context() {
    _socket = UnixSocket(waylandSocketPath());
  }

  dispatch() {
    if (_socket.hasData()) {
      var data = _socket.receive();
      if (data.isEmpty) return;
      _parseMessage(data);
    }

    // var data = connection!.readMsg();
    // if (data == null || data.data.isEmpty) return;
    // _parseMessage(data.data);
  }

  Future<void> connect() async {
    // await connection!.connect();
  }

  void _parseMessage(Uint8List data) {
    print('message size: ${data.buffer.lengthInBytes}');
    final ByteData byteData = ByteData.sublistView(data);

    int offset = 0;
    while (offset < data.length) {
      final start = offset;
      offset += 4; //skip opcode
      final int sizeAndOpcode = byteData.getUint32(offset, Endian.little);
      final int size = sizeAndOpcode >> 16;
      offset += 4;
      final int endOffset = offset + (size - 8);

      _messageHandler(
          Uint8List.sublistView(byteData).sublist(start, endOffset));

      offset = endOffset;
    }
  }

  void _messageHandler(data) {
    if (data.isEmpty) return;
    try {
      var result = parseMessage(data);
      var sender = result.$1;
      var opcode = result.$2;
      var args = result.$3;
      var fd = -1;

      var proxy = getProxy(sender);

      if (proxy is Dispatcher) {
        (proxy as Dispatcher).dispatch(opcode, fd, args);
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  sendMessage(Uint8List message, [int? fd]) {
    _socket.send(message, fd: fd);
  }

  int _nextClientId = 1;

  int allocateClientId() {
    return _nextClientId++;
  }

  Proxy getProxy(int id) {
    return _proxyMap[id] ?? UnknownProxy(id, this);
  }

  void register(Proxy proxy) {
    _proxyMap[proxy.objectId] = proxy;
  }

  void unRegister(Proxy proxy) {
    _proxyMap.remove(proxy.objectId);
  }

  final Map<int, Proxy> _proxyMap = {};
}
