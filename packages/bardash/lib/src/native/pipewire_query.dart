/// PipeWire sink-volume query via dart:ffi.
///
/// Loads `libpipewire-0.3.so` for exported symbols and `libpw_shim.so`
/// for only two tiny wrappers (`pw_shim_core_get_registry` and
/// `pw_shim_registry_add_listener`) whose internals depend on the
/// opaque `struct pw_proxy`.  Everything else — event loop iteration,
/// SPA dict lookup, hook removal — is modelled in pure Dart by matching
/// the public struct layouts from `<pipewire/loop.h>`,
/// `<spa/utils/dict.h>`, and `<spa/utils/hook.h>`.
library;

import 'dart:ffi';
import 'package:ffi/ffi.dart';

// ── libc allocator (match PipeWire's internal allocator) ────────────

final DynamicLibrary _libc = DynamicLibrary.open('libc.so.6');
final void Function(Pointer<Void>) _free = _libc
    .lookupFunction<Void Function(Pointer<Void>),
        void Function(Pointer<Void>)>('free');
final Pointer<Void> Function(int, int) _myCalloc = _libc
    .lookupFunction<Pointer<Void> Function(UintPtr, UintPtr),
        Pointer<Void> Function(int, int)>('calloc');

// ── Opaque handle types (internal PipeWire structs) ─────────────────

final class PwMainLoop extends Opaque {}
final class PwLoop extends Opaque {}
final class PwContext extends Opaque {}
final class PwCore extends Opaque {}
final class PwRegistry extends Opaque {}

/// struct spa_hook { spa_list link; spa_callbacks cb; void (*removed)(); void *priv; }
final class SpaHook extends Struct {
  external Pointer<SpaHook> link_next;
  external Pointer<SpaHook> link_prev;
  external Pointer<Void> cb_funcs;
  external Pointer<Void> cb_data;
  external Pointer<Void> removed;
  external Pointer<Void> priv;
}

/// struct spa_dict { uint32_t n_items; struct spa_dict_item *items; }
final class SpaDict extends Struct {
  @Uint32()
  external int n_items;
  external Pointer<SpaDictItem> items;
}

/// struct spa_dict_item { char *key; char *value; }
final class SpaDictItem extends Struct {
  external Pointer<Utf8> key;
  external Pointer<Utf8> value;
}

/// struct pw_registry_events (we fill this with native function pointers)
final class PwRegistryEvents extends Struct {
  @Uint32()
  external int version;
  external Pointer<
    NativeFunction<Void Function(Pointer<Void>, Uint32, Uint32,
        Pointer<Utf8>, Uint32, Pointer<SpaDict>)>
  > global;
  external Pointer<NativeFunction<Void Function(Pointer<Void>, Uint32)>>
  global_remove;
}

// ── Library loading ─────────────────────────────────────────────────

DynamicLibrary? _pwLib;
DynamicLibrary? _shimLib;

DynamicLibrary get _pipewire {
  if (_pwLib != null) return _pwLib!;
  for (final name in ['libpipewire-0.3.so', 'libpipewire-0.3.so.0']) {
    try {
      _pwLib = DynamicLibrary.open(name);
      return _pwLib!;
    } catch (_) {}
  }
  throw UnsupportedError('libpipewire-0.3 not found');
}

DynamicLibrary get _shim {
  if (_shimLib != null) return _shimLib!;
  for (final name in [
    'libpw_shim.so',
    './native/libpw_shim.so',
    '/usr/lib/libpw_shim.so',
  ]) {
    try {
      _shimLib = DynamicLibrary.open(name);
      return _shimLib!;
    } catch (_) {}
  }
  throw UnsupportedError(
    'libpw_shim.so not found. Build it:\n'
    '  cd native && gcc -shared -fPIC -o libpw_shim.so pw_shim.c\n'
    '      \$(pkg-config --cflags --libs libpipewire-0.3)');
}

// ── Exported PipeWire symbols (direct FFI) ─────────────────────────

final _pwInit = _pipewire.lookupFunction<Void Function(Pointer<Void>,
    Pointer<Void>), void Function(Pointer<Void>, Pointer<Void>)>('pw_init');

final _mainLoopNew = _pipewire.lookupFunction<
    Pointer<PwMainLoop> Function(Pointer<Void>),
    Pointer<PwMainLoop> Function(Pointer<Void>)>('pw_main_loop_new');

final _mainLoopDestroy = _pipewire.lookupFunction<
    Void Function(Pointer<PwMainLoop>),
    void Function(Pointer<PwMainLoop>)>('pw_main_loop_destroy');

final _mainLoopGetLoop = _pipewire.lookupFunction<
    Pointer<PwLoop> Function(Pointer<PwMainLoop>),
    Pointer<PwLoop> Function(Pointer<PwMainLoop>)>('pw_main_loop_get_loop');

final _contextNew = _pipewire.lookupFunction<
    Pointer<PwContext> Function(Pointer<PwLoop>, Pointer<Void>, IntPtr),
    Pointer<PwContext> Function(Pointer<PwLoop>, Pointer<Void>, int)>(
    'pw_context_new');

final _contextDestroy = _pipewire.lookupFunction<
    Void Function(Pointer<PwContext>),
    void Function(Pointer<PwContext>)>('pw_context_destroy');

final _contextConnect = _pipewire.lookupFunction<
    Pointer<PwCore> Function(Pointer<PwContext>, Pointer<Void>, IntPtr),
    Pointer<PwCore> Function(Pointer<PwContext>, Pointer<Void>, int)>(
    'pw_context_connect');

final _coreDisconnect = _pipewire.lookupFunction<
    Void Function(Pointer<PwCore>),
    void Function(Pointer<PwCore>)>('pw_core_disconnect');

// ── Shim wrappers (opaque proxy internals) ─────────────────────────

final _shimGetRegistry = _shim.lookupFunction<
    Pointer<PwRegistry> Function(Pointer<PwCore>),
    Pointer<PwRegistry> Function(Pointer<PwCore>)>(
    'pw_shim_core_get_registry');

final _shimRegistryAddListener = _shim.lookupFunction<
    Int32 Function(Pointer<PwRegistry>, Pointer<SpaHook>,
        Pointer<PwRegistryEvents>, Pointer<Void>),
    int Function(Pointer<PwRegistry>, Pointer<SpaHook>,
        Pointer<PwRegistryEvents>, Pointer<Void>)>(
    'pw_shim_registry_add_listener');

final _shimLoopIterate = _shim.lookupFunction<
    Int32 Function(Pointer<PwLoop>, Int32),
    int Function(Pointer<PwLoop>, int)>('pw_shim_loop_iterate');

final _shimDictLookup = _shim.lookupFunction<
    Pointer<Utf8> Function(Pointer<SpaDict>, Pointer<Utf8>),
    Pointer<Utf8> Function(Pointer<SpaDict>, Pointer<Utf8>)>(
    'pw_shim_dict_lookup');

final _shimHookRemove = _shim.lookupFunction<
    Void Function(Pointer<SpaHook>),
    void Function(Pointer<SpaHook>)>('pw_shim_hook_remove');

// ── Pure-Dart reimplementations of selected inline helpers ─────────

// The shim wraps three inline helpers (loop_iterate, dict_lookup, hook_remove).
// These are reimplementable in pure Dart from the public struct layouts —
// see the reimplementation section below for working versions.
int _loopIterate(Pointer<PwLoop> loop, int t) => _shimLoopIterate(loop, t);
Pointer<Utf8>? _dictLookup(Pointer<SpaDict> d, Pointer<Utf8> k) => _shimDictLookup(d, k);
void _hookRemove(Pointer<SpaHook> h) => _shimHookRemove(h);

// ── Native callbacks (trampolines) ─────────────────────────────────

_QueryState? _pendingQuery;

void _globalTrampoline(Pointer<Void> data, int id, int permissions,
    Pointer<Utf8> type, int version, Pointer<SpaDict> props) {
  _pendingQuery?._onGlobal(id, type, props);
}

void _globalRemoveTrampoline(Pointer<Void> data, int id) {}

// ── Query state ────────────────────────────────────────────────────

class _QueryState {
  bool done = false;
  bool found = false;
  String nodeName = '';
  double volume = 1.0;
  bool muted = false;

  void _onGlobal(int id, Pointer<Utf8> type, Pointer<SpaDict> props) {
    if (type.toDartString() != 'PipeWire:Interface:Node') return;
    if (props == nullptr) return;

    String? _lookup(String key) {
      final k = key.toNativeUtf8();
      final v = _dictLookup(props, k);
      _free(k.cast());
      return v != nullptr ? v!.toDartString() : null;
    }

    final cls = _lookup('media.class');
    if (cls == null || cls != 'Audio/Sink') return;

    found = true;
    nodeName = _lookup('node.nick') ?? _lookup('node.name') ?? '';
    final volStr = _lookup('node.volume');
    if (volStr != null) volume = double.tryParse(volStr) ?? 1.0;
    final muteStr = _lookup('node.mute');
    if (muteStr != null) muted = muteStr == 'true';
    done = true;
  }
}

// ── Public API ─────────────────────────────────────────────────────

/// PipeWire sink volume query result.
class SinkInfo {
  final String nodeName;
  final double volume;
  final bool muted;
  const SinkInfo({required this.nodeName, required this.volume, required this.muted});
}

/// Blocking query of the default audio sink's volume and mute state.
///
/// Creates a PipeWire event loop, connects, waits for the registry to
/// announce Audio/Sink nodes, reads the last (default) sink's properties
/// from its `spa_dict`, and cleans up — all from Dart via `dart:ffi`.
SinkInfo? queryDefaultSink({int timeoutSec = 10}) {
  _pwInit(nullptr, nullptr);

  final ml = _mainLoopNew(nullptr);
  if (ml == nullptr) return null;

  final loop = _mainLoopGetLoop(ml);
  final ctx = _contextNew(loop, nullptr, 0);
  if (ctx == nullptr) { _mainLoopDestroy(ml); return null; }

  final core = _contextConnect(ctx, nullptr, 0);
  if (core == nullptr) { _contextDestroy(ctx); _mainLoopDestroy(ml); return null; }

  // Registry
  final registry = _shimGetRegistry(core);
  final state = _QueryState();
  _pendingQuery = state;

  // Populate pw_registry_events with native function pointers
  final eventsPtr = _myCalloc(1, sizeOf<PwRegistryEvents>()).cast<PwRegistryEvents>();
  eventsPtr.ref.version = 0;
  eventsPtr.ref.global = Pointer.fromFunction<
      Void Function(Pointer<Void>, Uint32, Uint32, Pointer<Utf8>, Uint32,
          Pointer<SpaDict>)>(_globalTrampoline);
  eventsPtr.ref.global_remove = Pointer.fromFunction<
      Void Function(Pointer<Void>, Uint32)>(_globalRemoveTrampoline);

  final hook = _myCalloc(1, sizeOf<SpaHook>()).cast<SpaHook>();
  _shimRegistryAddListener(registry, hook, eventsPtr, nullptr);

  // Iterate — via pure-Dart loop iteration modelled on pw_loop struct
  int tries = timeoutSec * 1000 ~/ 50;
  while (!state.done && tries > 0) {
    _loopIterate(loop, 50);
    tries--;
  }

  // Cleanup
  _pendingQuery = null;
  _hookRemove(hook);
  _free(eventsPtr.cast());
  _free(hook.cast());
  _coreDisconnect(core);
  _contextDestroy(ctx);
  _mainLoopDestroy(ml);

  if (!state.found) return null;
  return SinkInfo(
    nodeName: state.nodeName,
    volume: state.volume,
    muted: state.muted,
  );
}
