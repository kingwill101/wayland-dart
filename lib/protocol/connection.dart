import 'dart:io';
import 'dart:typed_data';

import 'package:wayland/protocol/message.dart';

class WaylandConnection {
  Socket? _socket;

  WaylandConnection() {
    connect();
  }

  Socket get socket {
    if (_socket == null) {
      throw Exception('Socket is not connected');
    }
    return _socket!;
  }

  Stream<Uint8List> listen() {
    socket.listen((data){
      print(data);
    }, onDone: () {
      _socket = null;
    });
    return Stream.empty();
  }

  Future<void> connect() async {
    final socketPath = _getSocketPath();
    _socket = await Socket.connect(
        InternetAddress(socketPath, type: InternetAddressType.unix), 0);
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
    return '$runtimeDir/$display';
  }

  void sendMessage(WaylandMessage message) {
    final data = message.serialize();

    if (_socket == null) {
      throw Exception('Socket is not connected');
    }
    _socket?.add(data);

    // If the message contains file descriptors, we need to send them separately
    final fds = message.arguments.whereType<int>().toList();
    if (fds.isNotEmpty) {
      // This is a placeholder. In reality, you'd need to use platform-specific code
      // to send the file descriptors over the Unix domain socket.
      print('Sending file descriptors: $fds');
    }
  }
}
