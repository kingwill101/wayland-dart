import 'package:wayland/wayland.dart';

class Context {
  final WaylandConnection client;

  Context(this.client);

  void dispatch() {
    client.listen().forEach((data) {
      var result = parseMessage(data);

      var sender = result.$1;
      var opcode = result.$2;
      var args = result.$3;

      var proxy = getProxy(sender);

      if (proxy is Dispatcher) {
        (proxy as Dispatcher).dispatch(sender, opcode, args);
      }
    });
  }

  void sendMessage(WaylandMessage message) async {
    await client.connect();
    client.sendMessage(message);
  }

  int _nextClientId = 1;

  int allocateClientId() {
    return _nextClientId++;
  }

  Proxy getProxy(int id) {
    return _proxyMap[id]!;
  }

  void register(Proxy proxy) {
    _proxyMap[proxy.id] = proxy;
  }

  final Map<int, Proxy> _proxyMap = {};
}
