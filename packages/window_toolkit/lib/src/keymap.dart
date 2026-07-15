/// libxkbcommon FFI bindings for keyboard character decoding.
///
/// On `WlKeyboard.onKeymap` the compositor sends a file-descriptor
/// containing the xkb keymap.  This module loads it via `mmap`,
/// creates an xkb state, and on every key event converts the raw
/// keycode + modifier state into the typed UTF-8 character.
library;

import 'dart:convert' show utf8;
import 'dart:ffi';
import 'dart:io' show Platform;
import 'package:ffi/ffi.dart';
import 'package:wayland/wayland.dart' show munmap;

final DynamicLibrary _libc =
    DynamicLibrary.open(Platform.isLinux ? 'libc.so.6' : 'libc.dylib');

// Low-level mmap with PROT_READ only (keymap fd is read-only).
final Pointer<Void> Function(Pointer<Void>, int, int, int, int, int)
    _mmapReadOnly = _libc.lookupFunction<
        Pointer<Void> Function(Pointer<Void>, IntPtr, Int32, Int32, Int32,
            IntPtr),
        Pointer<Void> Function(Pointer<Void>, int, int, int, int,
            int)>('mmap');

final int Function(int) _close = _libc
    .lookupFunction<Int32 Function(Int32), int Function(int)>('close');

// ── Opaque handle types ────────────────────────────────────────────

final class XkbContext extends Opaque {}
final class XkbKeymap extends Opaque {}
final class XkbState extends Opaque {}

// ── Constants ──────────────────────────────────────────────────────

/// xkb_context_flags
abstract final class XkbCtx {
  static const int noFlags = 0;
}

/// xkb_keymap_format
abstract final class XkbKeymapFmt {
  static const int textV1 = 1;
}

/// xkb_key_direction
abstract final class XkbKeyDir {
  static const int up = 0;
  static const int down = 1;
}

// ── Shared library ─────────────────────────────────────────────────

DynamicLibrary? _lib;

DynamicLibrary get _xkb {
  if (_lib != null) return _lib!;
  for (final name in ['libxkbcommon.so', 'libxkbcommon.so.0']) {
    try {
      _lib = DynamicLibrary.open(name);
      return _lib!;
    } catch (_) {}
  }
  throw UnsupportedError(
    'libxkbcommon not found. Install it with:\n'
    '  apt install libxkbcommon-dev   (Debian/Ubuntu)\n'
    '  pacman -S libxkbcommon          (Arch)');
}

// ── FFI function bindings ─────────────────────────────────────────

final Pointer<XkbContext> Function(int) _ctxNew = _xkb
    .lookupFunction<Pointer<XkbContext> Function(Int32),
        Pointer<XkbContext> Function(int)>('xkb_context_new');

final void Function(Pointer<XkbContext>) _ctxUnref = _xkb
    .lookupFunction<Void Function(Pointer<XkbContext>),
        void Function(Pointer<XkbContext>)>('xkb_context_unref');

final Pointer<XkbKeymap> Function(
    Pointer<XkbContext>, Pointer<Utf8>, int, int, int) _keymapNewFromBuffer =
    _xkb.lookupFunction<
        Pointer<XkbKeymap> Function(
            Pointer<XkbContext>, Pointer<Utf8>, Int32, Int32, Int32),
        Pointer<XkbKeymap> Function(Pointer<XkbContext>, Pointer<Utf8>, int,
            int, int)>('xkb_keymap_new_from_buffer');

final void Function(Pointer<XkbKeymap>) _keymapUnref = _xkb
    .lookupFunction<Void Function(Pointer<XkbKeymap>),
        void Function(Pointer<XkbKeymap>)>('xkb_keymap_unref');

final Pointer<XkbState> Function(Pointer<XkbKeymap>) _stateNew = _xkb
    .lookupFunction<Pointer<XkbState> Function(Pointer<XkbKeymap>),
        Pointer<XkbState> Function(
            Pointer<XkbKeymap>)>('xkb_state_new');

final void Function(Pointer<XkbState>) _stateUnref = _xkb
    .lookupFunction<Void Function(Pointer<XkbState>),
        void Function(Pointer<XkbState>)>('xkb_state_unref');

final int Function(Pointer<XkbState>, int, int) _stateUpdateKey = _xkb
    .lookupFunction<
        Int32 Function(Pointer<XkbState>, Int32, Int32),
        int Function(Pointer<XkbState>, int, int)>('xkb_state_update_key');

final int Function(Pointer<XkbState>, int, Pointer<Utf8>, int) _stateKeyGetUtf8 =
    _xkb.lookupFunction<
        Int32 Function(Pointer<XkbState>, Int32, Pointer<Utf8>, IntPtr),
        int Function(Pointer<XkbState>, int, Pointer<Utf8>,
            int)>('xkb_state_key_get_utf8');

final void Function(Pointer<XkbState>, int, int, int, int, int, int)
    _stateUpdateMask = _xkb.lookupFunction<
        Void Function(
            Pointer<XkbState>, Uint32, Uint32, Uint32, Uint32, Uint32, Uint32),
        void Function(Pointer<XkbState>, int, int, int, int, int,
            int)>('xkb_state_update_mask');

// ── High-level wrapper ─────────────────────────────────────────────

/// Manages an xkb keymap + state for decoding raw keycodes to UTF-8.
class XkbKeyboard {
  Pointer<XkbContext> _ctx = nullptr;
  Pointer<XkbKeymap> _keymap = nullptr;
  Pointer<XkbState> _state = nullptr;
  Pointer<Void> _mappedKeymap = nullptr;
  int _mappedSize = 0;

  bool get isReady => _state != nullptr;

  /// Load a keymap from a Wayland `wl_keyboard.keymap` event FD.
  ///
  /// [format] is `WlKeyboardKeymapFormat.xkbV1.value` (1).
  /// [fd] is the file descriptor to mmap.
  /// [size] is the keymap size in bytes.
  void loadKeymap(int format, int fd, int size) {
    _clear();

    if (format != 1) { _close(fd); return; }

    // mmap the keymap fd with PROT_READ only (the compositor sends a
    // read-only fd, so PROT_WRITE would fail).
    const protRead = 1; // PROT_READ
    const mapShared = 1; // MAP_SHARED
    final mapped = _mmapReadOnly(nullptr, size, protRead, mapShared, fd, 0);
    if (mapped == nullptr || mapped.address == -1) { _close(fd); return; }

    _mappedKeymap = mapped;
    _mappedSize = size;
    _close(fd); // fd no longer needed after mmap

    _ctx = _ctxNew(XkbCtx.noFlags);
    if (_ctx == nullptr) return;

    final buf = _mappedKeymap.cast<Utf8>();
    _keymap = _keymapNewFromBuffer(_ctx, buf, size, XkbKeymapFmt.textV1, 0);
    if (_keymap == nullptr) {
      _ctxUnref(_ctx);
      _ctx = nullptr;
      return;
    }

    _state = _stateNew(_keymap);
  }

  /// Update modifier state from a `wl_keyboard.modifiers` event.
  void updateModifiers(int depressed, int latched, int locked, int group) {
    if (_state == nullptr) return;
    _stateUpdateMask(_state, depressed, latched, locked, group, group, 0);
  }

  /// Process a raw key event and return the UTF-8 character, or null.
  ///
  /// [keycode] is the raw Wayland keycode (add 8 for xkb).
  /// [pressed] is true for key press, false for release.
  String? keyEvent(int keycode, bool pressed) {
    if (_state == nullptr) return null;

    final xkbKeycode = keycode + 8;
    _stateUpdateKey(_state, xkbKeycode, pressed ? XkbKeyDir.down : XkbKeyDir.up);

    if (!pressed) return null;

    final buf = calloc<Uint8>(64);
    try {
      final len = _stateKeyGetUtf8(_state, xkbKeycode, buf.cast(), 64);
      if (len <= 0) return null;
      final bytes = buf.asTypedList(len);
      // Check for all-zero (invalid) or unprintable
      bool allZero = true;
      for (int i = 0; i < len; i++) { if (bytes[i] != 0) { allZero = false; break; } }
      if (allZero) return null;
      try {
        return utf8.decode(bytes.toList());
      } catch (_) { return null; }
    } finally {
      calloc.free(buf);
    }
  }

  /// Free all native resources.
  void dispose() {
    _clear();
  }

  void _clear() {
    if (_state != nullptr) {
      _stateUnref(_state);
      _state = nullptr;
    }
    if (_keymap != nullptr) {
      _keymapUnref(_keymap);
      _keymap = nullptr;
    }
    if (_ctx != nullptr) {
      _ctxUnref(_ctx);
      _ctx = nullptr;
    }
    if (_mappedKeymap != nullptr) {
      munmap(_mappedKeymap, _mappedSize);
      _mappedKeymap = nullptr;
      _mappedSize = 0;
    }
  }
}
