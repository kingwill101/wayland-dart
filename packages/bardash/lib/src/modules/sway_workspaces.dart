import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:window_toolkit/window_toolkit.dart';

import 'module.dart';

class _Workspace {
  final String name;
  final int num;
  final bool focused;
  final bool urgent;

  const _Workspace({
    required this.name,
    required this.num,
    required this.focused,
    required this.urgent,
  });
}

class SwayWorkspacesModule extends BarModule {
  @override
  String get name => 'sway/workspaces';

  late String _socketPath;
  Socket? _socket;
  bool _connected = false;
  final List<int> _readBuffer = [];
  final List<_Workspace> _workspaces = [];
  final List<double> _buttonStarts = [];

  @override
  void init(Map<String, String> config) {
    super.init(config);
    format = resolveFormat(config, '{name}', '');
    interval = parseInt(config, 'interval', 1);
    _socketPath = _findSocket();
  }

  String _findSocket() {
    final env = Platform.environment;
    return env['SWAYSOCK'] ??
        env['I3SOCK'] ??
        '/run/user/${env['UID'] ?? '1000'}/sway-ipc.${env['UID'] ?? '1000'}.sock';
  }

  @override
  void update() {
    if (!_connected) {
      _connect();
    } else {
      _sendRequest(1, []);
    }
  }

  void _connect() {
    Socket.connect(_socketPath, 0).then((socket) {
      _socket = socket;
      _connected = true;
      _readBuffer.clear();
      socket.listen(
        _onData,
        onDone: _onDisconnect,
        onError: (_) => _onDisconnect(),
      );
      _sendRequest(2, utf8.encode('["workspace"]'));
      _sendRequest(1, []);
    }).catchError((_) {
      _onDisconnect();
    });
  }

  void _sendRequest(int type, List<int> payload) {
    final length = payload.length;
    final header = ByteData(8);
    header.setUint32(0, length, Endian.little);
    header.setUint32(4, type, Endian.little);
    _socket?.add(header.buffer.asUint8List());
    if (payload.isNotEmpty) {
      _socket?.add(Uint8List.fromList(payload));
    }
  }

  void _onData(List<int> data) {
    _readBuffer.addAll(data);
    _processBuffer();
  }

  void _processBuffer() {
    while (_readBuffer.length >= 8) {
      final view = Uint8List.fromList(_readBuffer);
      final bd = ByteData.view(view.buffer);
      final length = bd.getUint32(0, Endian.little);
      final type = bd.getUint32(4, Endian.little);
      final total = 8 + length;
      if (_readBuffer.length < total) break;

      final payload = _readBuffer.sublist(8, total);
      _readBuffer.removeRange(0, total);

      if (type == 1) {
        _handleWorkspaces(payload);
      }
    }
  }

  void _handleWorkspaces(List<int> payload) {
    try {
      final json = utf8.decode(payload);
      final list = jsonDecode(json) as List;
      _workspaces
        ..clear()
        ..addAll(list.map((w) => _Workspace(
              name: w['name']?.toString() ?? '',
              num: (w['num'] ?? 0) as int,
              focused: w['focused'] ?? false,
              urgent: w['urgent'] ?? false,
            )));
    } catch (_) {}
  }

  void _onDisconnect() {
    _socket = null;
    _connected = false;
    _readBuffer.clear();
  }

  @override
  double draw(Painter painter, double x, double y) {
    _buttonStarts.clear();

    if (_workspaces.isEmpty) {
      output = 'sway N/A';
      painter.drawText(output, Offset(x, y), color: const Color(180, 180, 180));
      return painter.measureText(output).width;
    }

    output = '';
    double cx = x;
    const textSize = 12.0;
    const padding = 4.0;
    const spacing = 2.0;
    const buttonHeight = 16.0;

    for (final ws in _workspaces) {
      final label = format
          .replaceAll('{name}', ws.name)
          .replaceAll('{icon}', '')
          .replaceAll('{num}', ws.num > 0 ? ws.num.toString() : '');

      final measured = painter.measureText(label, size: textSize);
      final buttonWidth = measured.width + padding * 2 + 4;
      final buttonY = y - 1;

      _buttonStarts.add(cx);

      Color bg;
      Color fg;
      if (ws.focused) {
        bg = const Color(80, 80, 80);
        fg = const Color(255, 255, 255);
      } else if (ws.urgent) {
        bg = const Color(80, 30, 30);
        fg = const Color(255, 60, 60);
      } else {
        bg = const Color(50, 50, 50);
        fg = const Color(170, 170, 170);
      }

      final paint = Paint()..color = bg;
      painter.drawRect(Rect.fromLTWH(cx, buttonY, buttonWidth, buttonHeight), paint);
      painter.drawText(
        label,
        Offset(cx + padding, y),
        color: fg,
        size: textSize,
      );

      cx += buttonWidth + spacing;
    }

    _buttonStarts.add(cx);
    return cx - x;
  }

  @override
  bool get hasClick => true;

  @override
  void onClick(double x, double y, {int button = 0x110}) {
    for (int i = 0; i < _buttonStarts.length - 1; i++) {
      if (x >= _buttonStarts[i] && x < _buttonStarts[i + 1]) {
        if (i < _workspaces.length) {
          _focusWorkspace(_workspaces[i]);
        }
        break;
      }
    }
  }

  void _focusWorkspace(_Workspace ws) {
    final cmd = ws.num > 0
        ? 'workspace ${ws.num}'
        : 'workspace "${ws.name}"';
    if (_connected) {
      _sendRequest(3, utf8.encode(cmd));
    } else {
      Socket.connect(_socketPath, 0).then((socket) {
        final encoded = utf8.encode(cmd);
        final header = ByteData(8);
        header.setUint32(0, encoded.length, Endian.little);
        header.setUint32(4, 3, Endian.little);
        socket.add(header.buffer.asUint8List());
        socket.add(Uint8List.fromList(encoded));
        socket.close();
      }).catchError((_) {});
    }
  }
}
