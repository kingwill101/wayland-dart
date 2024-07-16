import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

typedef void MessageHandler(Uint8List data);

class WaylandConnection {
  Socket? _socket;
  final StreamController<List<int>> _outgoingMessages =
      StreamController<List<int>>();
  final List<List<int>> _bufferedMessages = [];
  MessageHandler? _messageHandler;

  set handler(MessageHandler? handler) {
    _messageHandler = handler;
  }

  Future<void> connect() async {
    final socketPath = _getSocketPath();
    print('Connecting to $socketPath');
    try {
      _socket = await Socket.connect(
        InternetAddress(socketPath, type: InternetAddressType.unix),
        0,
      );

      _socket?.listen((data) {
        _handleIncomingMessage(data);
      }, onError: (error) {
        print('Socket error: $error');
        _close();
      }, onDone: () {
        print('Socket closed');
        _close();
      });

      // Send outgoing messages
      _outgoingMessages.stream.listen((data) {
        _sendMessage(data);
      });

      // Send buffered messages
      _sendBufferedMessages();
    } catch (e) {
      print('Failed to connect: $e');
      _close();
    }
  }

  void _sendMessage(List<int> data) {
    try {
      _socket?.add(data);
    } on SocketException catch (e) {
      print('SocketException during add: $e');
      _bufferMessage(data);
      _close();
    }
  }

  void _handleIncomingMessage(Uint8List data) {
    print('Received');
    print('\tdata: $data');
    if (_messageHandler != null) {
      _messageHandler!(data);
    }
  }

  void _close() {
    _socket?.close();
    _socket = null;
  }

  void sendMessage(List<int> data) {
    if (_socket == null) {
      _bufferMessage(data);
      connect();
    } else {
      _sendMessage(data);
    }
  }

  void _bufferMessage(List<int> data) {
    _bufferedMessages.add(data);
  }

  void _sendBufferedMessages() {
    while (_bufferedMessages.isNotEmpty) {
      final message = _bufferedMessages.removeAt(0);
      sendMessage(message);
    }
  }

  Future<void> reconnectAndResend(List<int> data) async {
    await connect();
    _sendBufferedMessages();
    sendMessage(data);
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
    // return '$runtimeDir/$display';
    return '$display';
  }
}
