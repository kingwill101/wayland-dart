import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:wayland/src/protocol/log.dart';


class WaylandConnection {
  RawSocket? _socket;

  SocketMessage? readMsg() {
    if (_socket == null) return null;
    _socket?.readEventsEnabled = true;
    return _socket?.readMessage();
  }

  Future<void> connect() async {
    final socketPath = waylandSocketPath();
    logLn('Connecting to $socketPath');
    try {
      _socket = await RawSocket.connect(
        InternetAddress(socketPath, type: InternetAddressType.unix),
        0,
      );


      _socket?.readEventsEnabled = true;
      _socket?.writeEventsEnabled = true;
    } catch (e) {
      logLn('Failed to connect: $e');
      _close();
    }
  }

  void _close() {
    _socket?.close();
    _socket = null;
  }



  Future<void> sendMessage(Uint8List message) async {
    if (_socket != null) {
      logLn("socket writing: $message");
      int sent = _socket!.write(message);

      if (sent < message.length) {
        logLn('Warning: Only partial data was sent');
      }
    } else {
      logLn('Warning: Socket is not connected, unable to send message');
    }
  }
}


  String waylandSocketPath() {
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