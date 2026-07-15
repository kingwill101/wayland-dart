/// Hyprland Unix-socket IPC via raw dart:ffi.
///
/// Calls `socket()`, `connect()`, `write()`, `read()` directly from
/// libc — no subprocess, no C shim.  Same technique the Wayland
/// connection itself uses.
///
/// Also provides an event-driven listener on Hyprland's event socket
/// (`socket2.sock`) so modules get instant updates instead of polling.
library;

import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';

// ── libc socket functions ─────────────────────────────────────────

final DynamicLibrary _libc =
    DynamicLibrary.open(Platform.isLinux ? 'libc.so.6' : 'libc.dylib');

// int socket(int domain, int type, int protocol)
final int Function(int, int, int) _socket = _libc
    .lookupFunction<Int32 Function(Int32, Int32, Int32),
        int Function(int, int, int)>('socket');

// int connect(int fd, Pointer<Void> addr, int addrlen)
final int Function(int, Pointer<Void>, int) _connect = _libc
    .lookupFunction<Int32 Function(Int32, Pointer<Void>, Uint32),
        int Function(int, Pointer<Void>, int)>('connect');

// int write(int fd, Pointer<Void> buf, int count)
final int Function(int, Pointer<Void>, int) _write = _libc
    .lookupFunction<IntPtr Function(Int32, Pointer<Void>, IntPtr),
        int Function(int, Pointer<Void>, int)>('write');

// int read(int fd, Pointer<Void> buf, int count)
final int Function(int, Pointer<Void>, int) _read = _libc
    .lookupFunction<IntPtr Function(Int32, Pointer<Void>, IntPtr),
        int Function(int, Pointer<Void>, int)>('read');

// int close(int fd)
final int Function(int) _close = _libc
    .lookupFunction<Int32 Function(Int32), int Function(int)>('close');

// fcntl + non-blocking I/O
final int Function(int, int, int) _fcntl = _libc
    .lookupFunction<Int32 Function(Int32, Int32, Int32),
        int Function(int, int, int)>('fcntl');

const int _F_SETFL = 4;
const int _O_NONBLOCK = 2048;

// ── Socket path ───────────────────────────────────────────────────

const int _AF_UNIX = 1;
const int _SOCK_STREAM = 1;

String? _cachedPath;
String? _cachedEventPath;

String get _socketPath {
  if (_cachedPath != null) return _cachedPath!;
  final base = _socketBase();
  _cachedPath = '$base/.socket.sock';
  return _cachedPath!;
}

String get _eventSocketPath {
  if (_cachedEventPath != null) return _cachedEventPath!;
  final base = _socketBase();
  _cachedEventPath = '$base/.socket2.sock';
  return _cachedEventPath!;
}

String _socketBase() {
  final env = Platform.environment;
  final sig = env['HYPRLAND_INSTANCE_SIGNATURE'];
  if (sig == null || sig.isEmpty) {
    throw UnsupportedError('\$HYPRLAND_INSTANCE_SIGNATURE not set');
  }
  final runtime = env['XDG_RUNTIME_DIR'] ?? '/run/user/${env["UID"] ?? "1000"}';
  return '$runtime/hypr/$sig';
}

// ── Public API ────────────────────────────────────────────────────

/// Send a Hyprland IPC command via Unix domain socket.
///
/// If [useJson] is true (default), prefixes with `j/` for JSON response.
/// Set to false for commands like `dispatch` that expect plain text.
/// Falls back to `hyprctl $cmd -j` on socket errors.
dynamic hyprctl(String command, {bool useJson = true}) {
  final result = _tryDirectIpc(command, useJson: useJson);
  if (result != null) return result;

  if (useJson) {
    return _fallback(command);
  } else {
    // Non-JSON fallback: use hyprctl without -j
    try {
      final parts = command.split(' ');
      final r = Process.runSync('hyprctl', parts, runInShell: true);
      if (r.exitCode != 0) return null;
      return (r.stdout as String).trim();
    } catch (_) { return null; }
  }
}

dynamic _tryDirectIpc(String command, {bool useJson = true}) {
  try {
    final path = _socketPath;
    final sunPath = path.toNativeUtf8();
    if (sunPath.length > 107) {
      calloc.free(sunPath);
      return null;
    }

    final fd = _socket(_AF_UNIX, _SOCK_STREAM, 0);
    if (fd < 0) { calloc.free(sunPath); return null; }

    // Build sockaddr_un
    final addr = calloc<Uint8>(110);
    addr[0] = _AF_UNIX;
    addr[1] = 0;
    for (int i = 0; i < path.length; i++) {
      addr[2 + i] = path.codeUnitAt(i);
    }

    final connRet = _connect(fd, addr.cast(), 110);
    calloc.free(addr);
    calloc.free(sunPath);

    if (connRet < 0) { _close(fd); return null; }

    final cmdStr = useJson ? 'j/' + command : '/' + command;
    final cmdPtr = cmdStr.toNativeUtf8();
    _write(fd, cmdPtr.cast(), cmdStr.length);
    calloc.free(cmdPtr);

    final buf = calloc<Uint8>(65536);
    final total = _read(fd, buf.cast(), 65536);
    _close(fd);

    if (total <= 0) { calloc.free(buf); return null; }

    final response = utf8.decode(buf.asTypedList(total));
    calloc.free(buf);

    if (response.isEmpty) return null;
    try {
      return jsonDecode(response);
    } catch (_) {
      return response;
    }
  } catch (_) {
    return null;
  }
}

dynamic _fallback(String command) {
  final parts = command.split(' ');
  try {
    final r = Process.runSync('hyprctl', [...parts, '-j'], runInShell: true);
    if (r.exitCode != 0) return null;
    return jsonDecode(r.stdout as String);
  } catch (_) {
    return null;
  }
}

/// Check if Hyprland IPC is available (socket file exists).
bool get isAvailable {
  try {
    return File(_socketPath).existsSync();
  } catch (_) {
    return false;
  }
}

// ── Event socket (persistent, non-blocking) ───────────────────────
//
// Hyprland exposes `.socket2.sock` which streams events as they happen.
// Events arrive as `eventname>>data\n` lines.  We keep a persistent
// non-blocking connection and drain pending events on each call.

int _eventFd = -1;
String _eventBuffer = '';

/// Callback type for Hyprland events.
typedef void EventCallback(String event, String data);

EventCallback? _onEvent;

/// Register a callback for Hyprland events from the event socket.
/// Only one listener is supported at a time.
void onEvent(void Function(String event, String data) callback) {
  _onEvent = callback;
}

/// Remove the event callback and close the event socket.
void clearEventCallback() {
  _onEvent = null;
  _closeEventSocket();
}

int _connectEventSocket() {
  if (_eventFd >= 0) return _eventFd; // already connected

  try {
    final path = _eventSocketPath;
    if (!File(path).existsSync()) return -1;

    final sunPath = path.toNativeUtf8();
    if (sunPath.length > 107) {
      calloc.free(sunPath);
      return -1;
    }

    final fd = _socket(_AF_UNIX, _SOCK_STREAM, 0);
    if (fd < 0) { calloc.free(sunPath); return -1; }

    final addr = calloc<Uint8>(110);
    addr[0] = _AF_UNIX;
    addr[1] = 0;
    for (int i = 0; i < path.length; i++) {
      addr[2 + i] = path.codeUnitAt(i);
    }

    final connRet = _connect(fd, addr.cast(), 110);
    calloc.free(addr);
    calloc.free(sunPath);

    if (connRet < 0) { _close(fd); return -1; }

    // Set non-blocking so reads never block the event loop.
    _fcntl(fd, _F_SETFL, _O_NONBLOCK);

    _eventFd = fd;
    return fd;
  } catch (_) {
    return -1;
  }
}

void _closeEventSocket() {
  if (_eventFd >= 0) {
    _close(_eventFd);
    _eventFd = -1;
  }
  _eventBuffer = '';
}

/// Check for pending events on the event socket and dispatch them.
/// Call this periodically (e.g. from a module's update()).
/// The socket is non-blocking so reads return immediately.
void pollEvents() {
  if (_onEvent == null) return;

  final fd = _connectEventSocket();
  if (fd < 0) return;

  // Try reading — non-blocking, so it returns immediately with whatever
  // data is available, or -1 / EAGAIN if nothing yet.
  final buf = calloc<Uint8>(65536);
  final total = _read(fd, buf.cast(), 65536);
  if (total <= 0) {
    calloc.free(buf);
    // -1 with EAGAIN = no data, keep connection open.
    // 0 or other negative = connection closed, reconnect next time.
    if (total == 0) _closeEventSocket();
    return;
  }

  final chunk = utf8.decode(buf.asTypedList(total));
  calloc.free(buf);
  _eventBuffer += chunk;

  // Process complete lines
  while (_eventBuffer.contains('\n')) {
    final nl = _eventBuffer.indexOf('\n');
    final line = _eventBuffer.substring(0, nl);
    _eventBuffer = _eventBuffer.substring(nl + 1);

    if (line.isEmpty) continue;

    final sep = line.indexOf('>>');
    if (sep < 0) continue;

    final event = line.substring(0, sep);
    final data = line.substring(sep + 2);
    _onEvent!(event, data);
  }

  // Safety valve: discard if buffer grows too large.
  if (_eventBuffer.length > 65536) _eventBuffer = '';
}

/// Reset cached socket paths (useful for testing).
void resetCache() {
  _cachedPath = null;
  _cachedEventPath = null;
}
