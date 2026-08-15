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
    Socket.connect(_socketPath, 0)
        .then((socket) {
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
        })
        .catchError((_) {
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
        ..addAll(
          list.map(
            (w) => _Workspace(
              name: w['name']?.toString() ?? '',
              num: (w['num'] ?? 0) as int,
              focused: w['focused'] ?? false,
              urgent: w['urgent'] ?? false,
            ),
          ),
        );
      _rebuildWidget();
      requestRepaint?.call();
    } catch (_) {}
  }

  void _onDisconnect() {
    _socket = null;
    _connected = false;
    _readBuffer.clear();
  }

  void _rebuildWidget() {
    if (_workspaces.isEmpty) {
      widget = null;
      output = 'sway N/A';
      return;
    }

    final children = <Widget>[];
    for (final ws in _workspaces) {
      final label = format
          .replaceAll('{name}', ws.name)
          .replaceAll('{icon}', '')
          .replaceAll('{num}', ws.num > 0 ? ws.num.toString() : '');
      final button =
          Button(
              label.isEmpty ? (ws.num > 0 ? '${ws.num}' : '?') : label,
              textColor: ws.focused
                  ? const Color(255, 255, 255)
                  : ws.urgent
                  ? const Color(255, 96, 96)
                  : const Color(170, 170, 170),
              backgroundColor: ws.focused
                  ? const Color(80, 80, 80)
                  : ws.urgent
                  ? const Color(80, 30, 30)
                  : const Color(50, 50, 50),
              hoverColor: const Color(96, 112, 144),
              padding: 3,
              charWidth: 7,
              charHeight: 14,
            )
            ..styleId = 'workspace-${ws.num}'
            ..addClass('workspace')
            ..addClass('button');
      if (ws.focused) {
        button.addClass('focused');
        button.addPseudoClass('active');
      }
      if (ws.urgent) button.addClass('urgent');
      button.onClick = () {
        _focusWorkspace(ws);
        return true;
      };
      children.add(button);
      if (ws != _workspaces.last) children.add(Spacer()..width = 2);
    }
    widget = HBox(spacing: 0, children: children);
    output = '';
  }

  void _focusWorkspace(_Workspace ws) {
    final cmd = ws.num > 0 ? 'workspace ${ws.num}' : 'workspace "${ws.name}"';
    if (_connected) {
      _sendRequest(3, utf8.encode(cmd));
    } else {
      Socket.connect(_socketPath, 0)
          .then((socket) {
            final encoded = utf8.encode(cmd);
            final header = ByteData(8);
            header.setUint32(0, encoded.length, Endian.little);
            header.setUint32(4, 3, Endian.little);
            socket.add(header.buffer.asUint8List());
            socket.add(Uint8List.fromList(encoded));
            socket.close();
          })
          .catchError((_) {});
    }
  }

  @override
  void onScroll(double delta) {
    if (delta == 0 || _workspaces.isEmpty) return;
    final current = _workspaces.indexWhere((ws) => ws.focused);
    if (current < 0) return;
    final next = (current + (delta < 0 ? 1 : -1)).clamp(
      0,
      _workspaces.length - 1,
    );
    if (next != current) _focusWorkspace(_workspaces[next]);
  }
}
