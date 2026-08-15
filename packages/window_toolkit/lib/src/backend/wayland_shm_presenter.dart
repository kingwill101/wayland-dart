import 'dart:io';

import 'package:wayland/wayland.dart';

import '../drawing/color.dart';
import '../painter/painter.dart';
import '../painter/skia_painter.dart';
import 'connection.dart';
import 'wayland_surface.dart';

/// Owns Wayland SHM buffers and presents toolkit paint commands.
///
/// Overlay clients provide only a draw callback. Pool creation, buffer reuse,
/// release handling, and frame commits stay inside the toolkit backend.
class WaylandShmPresenter {
  final WaylandConnection connection;
  final WaylandSurface surface;
  final int width;
  final int height;
  final int bufferCount;
  final void Function()? onBufferAvailable;
  final String logTag;

  final List<WlShmPool?> _pools;
  final List<WlBuffer?> _buffers;
  final List<int> _fds;
  final List<bool> _busy;
  int _front = 0;
  bool _initialized = false;
  bool _disposed = false;

  WaylandShmPresenter({
    required this.connection,
    required this.surface,
    required this.width,
    required this.height,
    this.bufferCount = 2,
    this.onBufferAvailable,
    this.logTag = '[wt:shm]',
  }) : assert(width > 0),
       assert(height > 0),
       assert(bufferCount > 0),
       _pools = List<WlShmPool?>.filled(bufferCount, null),
       _buffers = List<WlBuffer?>.filled(bufferCount, null),
       _fds = List<int>.filled(bufferCount, -1),
       _busy = List<bool>.filled(bufferCount, false);

  int get surfaceId => surface.objectId;

  bool get isInitialized => _initialized;

  bool get isDisposed => _disposed;

  /// Allocates the SHM pool(s). Safe to call more than once.
  bool initialize() {
    if (_disposed) return false;
    if (_initialized) return true;

    final stride = width * 4;
    final slotSize = stride * height;
    for (var i = 0; i < bufferCount; i++) {
      final fd = createAnonymousFile(slotSize);
      if (fd < 0) {
        stderr.writeln('$logTag unable to create fd for slot $i');
        dispose();
        return false;
      }
      _fds[i] = fd;
      final pool = connection.shm.createPool(fd, slotSize).getOrElse((e) {
        stderr.writeln('$logTag createPool slot=$i failed: $e');
        return WlShmPool(connection.context);
      });
      _pools[i] = pool;
      final buffer = pool.createBuffer(0, width, height, stride, 0).getOrElse((
        e,
      ) {
        stderr.writeln('$logTag createBuffer slot=$i failed: $e');
        return WlBuffer(connection.context);
      });
      final slot = i;
      buffer.onRelease((_) {
        if (_disposed) return;
        _busy[slot] = false;
        onBufferAvailable?.call();
      });
      _buffers[i] = buffer;
    }
    _initialized = true;
    return true;
  }

  /// Paints and presents one frame, returning false while all buffers are in
  /// flight. The presenter clears the frame before invoking [draw].
  bool present(
    void Function(Painter painter) draw, {
    Color clearColor = const Color(0, 0, 0, 0),
  }) {
    if (_disposed || !initialize()) return false;

    var slot = 1 - _front;
    if (slot >= bufferCount || _busy[slot] || _buffers[slot] == null) {
      slot = _front;
    }
    final buffer = _buffers[slot];
    final fd = _fds[slot];
    if (_busy[slot] || buffer == null || fd < 0) return false;

    final painter = SkiaPainter(fd, width, height);
    try {
      painter.clear(clearColor);
      draw(painter);
      painter.flush();
    } finally {
      painter.dispose();
    }

    _busy[slot] = true;
    _front = slot;
    surface.attach(buffer);
    surface.damage(width, height);
    surface.commit();
    return true;
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    for (var i = 0; i < bufferCount; i++) {
      _buffers[i]?.destroy();
      _buffers[i] = null;
      _pools[i]?.destroy();
      _pools[i] = null;
      if (_fds[i] >= 0) {
        closeFd(_fds[i]);
        _fds[i] = -1;
      }
      _busy[i] = false;
    }
    _initialized = false;
  }
}
