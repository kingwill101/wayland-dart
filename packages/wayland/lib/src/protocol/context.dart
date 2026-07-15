import 'dart:io' show Platform, stderr;
import 'dart:typed_data';

import 'package:wayland/wayland.dart';

class Context {
  late UnixSocket _socket;
  bool _connected = true;

  /// Whether the Wayland socket is still alive.
  bool get isConnected => _connected;

  Context() {
    _socket = UnixSocket.connect(Address.file(_waylandSocketPath()));
    // Increase socket buffers so the compositor can push events during
    // VM service pauses (GC, heap snapshot) without filling up and
    // disconnecting us. Default is often 208-256 KB; 1 MB gives headroom.
    _socket.setReceiveBufferSize(1024 * 1024); // 1 MB receive buffer
    _socket.setSendBufferSize(512 * 1024);     // 512 KB send buffer
  }

  static String _waylandSocketPath() {
    if (Platform.environment.containsKey('WAYLAND_SOCKET')) {
      final fd = int.parse(Platform.environment['WAYLAND_SOCKET']!);
      return 'fd://$fd';
    }
    final runtimeDir = Platform.environment['XDG_RUNTIME_DIR'];
    if (runtimeDir == null) {
      throw Exception('XDG_RUNTIME_DIR is not set');
    }
    final display = Platform.environment['WAYLAND_DISPLAY'] ?? 'wayland-0';
    if (Platform.environment['IGNORE_DISPLAY'] != null) return display;
    return '$runtimeDir/$display';
  }

  /// Blocks until data is available, then reads and parses all pending messages.
  void dispatch() {
    dispatchTimeout(-1);
  }

  /// Reads all available messages, waiting up to [timeoutMs] if no data yet.
  /// Returns true if any messages were processed.
  /// Pass -1 to block forever, 0 to not block at all.
  bool dispatchTimeout(int timeoutMs) {
    if (!_connected) return false;
    try {
      if (timeoutMs != 0 && !_socket.waitForData(timeoutMs)) return false;
      var processed = false;
      while (_socket.hasData) {
        var data = _socket.receive();
        if (data.isEmpty) return processed;
        _parseMessage(data);
        processed = true;
      }
      return processed;
    } catch (e, st) {
      stderr.writeln('[wt] Wayland socket error — connection lost');
      _connected = false;
      return false;
    }
  }

  /// Closes the underlying socket and releases native resources.
  void close() {
    _socket.close();
  }

  Future<void> connect() async {}

  void _parseMessage(Uint8List data) {
    final ByteData byteData = ByteData.sublistView(data);

    int offset = 0;
    while (offset < data.length) {
      if (offset + 8 > data.length) break;

      final int sizeAndOpcode = byteData.getUint32(offset + 4, Endian.little);
      final int size = sizeAndOpcode >> 16;

      if (size < 8) break;

      final int endOffset = offset + size;
      if (endOffset > data.length) break;

      final msg = Uint8List(endOffset - offset);
      msg.setRange(0, msg.length, data, offset);
      _messageHandler(msg);

      offset = endOffset;
    }
  }

  void _messageHandler(Uint8List data) {
    if (data.isEmpty) return;
    try {
      var result = parseMessage(data);
      var sender = result.$1;
      var opcode = result.$2;
      var args = result.$3;

      // Auto-unregister on wl_display.delete_id (sender=1, opcode=1)
      if (sender == 1 && opcode == 1 && args.length >= 4) {
        final id = ByteData.view(args.buffer).getUint32(0, Endian.little);
        unRegisterById(id);
      }

      var proxy = getProxy(sender);
      if (proxy is Dispatcher) {
        (proxy as Dispatcher).dispatch(opcode, -1, args);
      }
    } catch (e, st) {
      stderr.writeln('Error: $e\n$st');
    }
  }

  void sendMessage(Uint8List message, [int? fd]) {
    if (!_connected) return;
    try {
      _socket.send(message, fd: fd ?? -1);
    } catch (_) {
      _connected = false;
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

  void unRegister(Proxy proxy) {
    _proxyMap.remove(proxy.objectId);
  }

  void unRegisterById(int id) {
    _proxyMap.remove(id);
  }

  final Map<int, Proxy> _proxyMap = {};
}
