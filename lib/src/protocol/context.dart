import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:wayland/wayland.dart';

typedef void MessageHandler(Uint8List data);

class Context {
  RawSocket? _socket;
  MessageHandler? _messageHandler;

  Context();

  Future<void> connect() async {
    final socketPath = _getSocketPath();
    print('Connecting to $socketPath');
    try {
      _socket = await RawSocket.connect(
        InternetAddress(socketPath, type: InternetAddressType.unix),
        0,
      );

      _socket?.listen((e) {
        switch (e) {
          case RawSocketEvent.read:
            final SocketMessage? message = _socket?.readMessage();
            if (message == null || message.data.isEmpty) {
              return;
            }
            if (_messageHandler != null) {
              _messageHandler!(message.data);
            }
            break;
          case RawSocketEvent.readClosed:
            break;
          case RawSocketEvent.closed:
            print("socket closed");
            break;
          case RawSocketEvent.write:
            break;
        }
      });

      _socket?.readEventsEnabled = true;
      _socket?.writeEventsEnabled = true;

      _messageHandler = (data) {
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
      };
    } catch (e) {
      print('Failed to connect: $e');
      _close();
    }
  }

  void _close() {
    _socket?.close();
    _socket = null;
  }

  String _getSocketPath() {
    if (Platform.environment.containsKey('WAYLAND_SOCKET')) {
      // Use the pre-established connection
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

  Future<void> sendMessage(Uint8List message) async {
    if (_socket != null) {
      print("socket writing: $message");
      int sent = _socket!.write(message);
      if (sent < message.length) {
        print('Warning: Only partial data was sent');
      }
    } else {
      print('Warning: Socket is not connected, unable to send message');
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
