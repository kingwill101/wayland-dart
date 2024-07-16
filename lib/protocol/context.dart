import 'dart:io';

import 'package:wayland/wayland.dart';

class Context {
  WaylandConnection client;

  Context(this.client);

  void dispatch() {
    client.handler = (data) {
      var result = parseMessage(data);
      var sender = result.$1;
      var opcode = result.$2;
      var args = result.$3;
      var fd = -1;

      var proxy = getProxy(sender);

      if (proxy is Dispatcher) {
        (proxy as Dispatcher).dispatch(opcode, fd, args);
      }
    };
  }

  Future<void> connect() async {
    await client.connect();
  }

  Future<void> sendMessage(WaylandMessage message) async {
    final data = message.serialize();
    print('Sending');
    print('\tmessage: $data');
    print('\tsize: ${data.lengthInBytes}');
    try {
      client.sendMessage(data);
    } on SocketException catch (e) {
      print('SocketException in sendMessage: $e');
      await client.reconnectAndResend(data);
    } catch (e) {
      print('Exception in sendMessage: $e');
    }
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

  final Map<int, Proxy> _proxyMap = {};
}
