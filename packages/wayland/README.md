# Dart Wayland Client Library

Pure Dart implementation of the [Wayland](https://wayland.freedesktop.org/) client protocol.
Provides FFI bindings to `libc` for Unix socket communication and shared memory — no C
compilation required at build time.

- Full core Wayland protocol (`wl_display`, `wl_shm`, `wl_compositor`, `wl_seat`, …)
- 80+ extensions: xdg-shell, layer-shell, input-method, tablet, fractional-scale, ext-*…
- Code generation from Wayland protocol XML via built-in scanner
- Works with AOT compilation (`dart build`) via native assets

## Packages

This repo is a monorepo managed with Melos:

| Package | Description |
|---------|-------------|
| `packages/wayland` | Core Wayland protocol bindings + code generator |
| `packages/window_toolkit` | Widget toolkit + layer-shell window backend |
| `packages/gl` | OpenGL integration |
| `packages/bardash` | Wayland bar (desktop panel) |

## Installation

```yaml
# pubspec.yaml
dependencies:
  wayland:
    git: https://github.com/your-account/dart_wayland.git
    path: packages/wayland
```

Or if published on pub.dev:

```yaml
dependencies:
  wayland: ^1.0.0
```

## Quick Start

```dart
import 'dart:typed_data';
import 'package:wayland/wayland.dart';

void main() async {
  final app = WaylandApp();
  await app.init();
  app.run();
}

class WaylandApp {
  late Context context;
  late WlDisplay display;
  late WlRegistry registry;
  late WlCompositor compositor;
  late WlShm shm;
  late XdgWmBase xdgWmBase;
  late WlSurface surface;
  late XdgSurface xdgSurface;
  late XdgToplevel toplevel;
  int width = 800;
  int height = 600;
  bool running = true;

  WlShmPool? _pool;
  int _fd = -1;

  Future<void> init() async {
    context = Context();
    await context.connect();

    display = WlDisplay(context);
    display.onError((e) { stderr.writeln('display error: $e'); exit(1); });

    registry = display.getRegistry().getOrElse((_) { exit(1); });
    registry.onGlobal(_onGlobal);
    _roundtrip(); _roundtrip(); // wait for globals

    surface = compositor.createSurface().getOrElse((_) { exit(1); });
    xdgSurface = xdgWmBase.getXdgSurface(surface).getOrElse((_) { exit(1); });
    xdgSurface.onConfigure((e) {
      xdgSurface.ackConfigure(e.serial);
      _drawFrame();
      surface.commit();
    });
    toplevel = xdgSurface.getToplevel().getOrElse((_) { exit(1); });
    toplevel.onConfigure((e) {
      if (e.width > 0 && e.height > 0) { width = e.width; height = e.height; }
    });
    toplevel.onClose((_) { running = false; });
    toplevel.setTitle('Dart Wayland');
    toplevel.setAppId('dart-wayland');
    surface.commit();
  }

  void run() { while (running) { context.dispatch(); } }

  void _roundtrip() {
    final cb = display.sync().getOrElse((_) => WlCallback(context));
    var done = false;
    cb.onDone((_) { done = true; });
    while (!done) context.dispatch();
  }

  void _onGlobal(dynamic global) {
    switch (global.interface) {
      case 'wl_compositor':
        compositor = WlCompositor(context);
        registry.bind(global.name, global.interface, global.version, compositor.objectId);
      case 'wl_shm':
        shm = WlShm(context);
        registry.bind(global.name, global.interface, global.version, shm.objectId);
      case 'xdg_wm_base':
        xdgWmBase = XdgWmBase(context);
        xdgWmBase.onPing((p) => xdgWmBase.pong(p.serial));
        registry.bind(global.name, global.interface, global.version, xdgWmBase.objectId);
    }
  }

  void _drawFrame() {
    final stride = width * 4;
    final size = stride * height;
    if (_pool == null || size > _poolSize) {
      _pool?.destroy();
      closeFd(_fd);
      _fd = createAnonymousFile(size);
      _pool = shm.createPool(_fd, size).getOrElse((_) { exit(1); });
    }
    final buffer = _pool!.createBuffer(0, width, height, stride, 0).getOrElse((_) { exit(1); });
    buffer.onRelease((_) => buffer.destroy());
    final pixels = Uint8List(size);
    // fill with white pixels …
    for (var i = 0; i < pixels.length; i += 4) { pixels[i]=0xFF; pixels[i+1]=0xFF; pixels[i+2]=0xFF; pixels[i+3]=0xFF; }
    writeToFd(_fd, pixels);
    surface.attach(buffer, 0, 0);
  }
}
```

## Protocol Generation

Protocol bindings are **generated from XML spec files** using the built-in scanner.
The scanner fetches protocol XMLs from remote URLs (with local caching), parses
them, and outputs Dart classes.

### Generate All Protocols

```bash
cd packages/wayland
dart run bin/scanner.dart scan --protocols=protocols.yaml
```

This processes every entry in `protocols.yaml` and writes generated `.dart` files
to `lib/protocols/`.

### Generate a Single Protocol

```bash
dart run bin/scanner.dart scan \
  -i https://gitlab.freedesktop.org/wayland/wayland-protocols/-/raw/main/staging/ext-idle-notify/ext-idle-notify-v1.xml \
  -o staging/ext-idle-notify/ext_idle_notify_v1.dart \
  --prefix=zwlr_
```

Flags:

| Flag | Description |
|------|-------------|
| `-i` | URL or local path to the protocol XML |
| `-o` | Output path (relative to `lib/protocols/`) |
| `--prefix` | Prefix to strip from interface names (e.g. `zwlr_`) |
| `--pkg` | Dart package name (default: `wayland`) |
| `--protocols` | YAML file listing multiple protocols |
| `--force` | Re-download XMLs, bypassing the cache |
| `--clean` | Delete the output directory before generation |

### Adding a New Protocol

1. Find the XML spec URL from the
   [wayland-protocols](https://gitlab.freedesktop.org/wayland/wayland-protocols)
   or [wlroots](https://gitlab.freedesktop.org/wlroots/wlr-protocols) repository.

2. Add an entry to `protocols.yaml`:

```yaml
- name: my-protocol-v1.xml
  input: "https://example.org/my-protocol-v1.xml"
  output: "staging/my-protocol/my_protocol_v1.dart"
  # If the protocol uses a prefix like zwlr_, specify it to strip cleanly:
  prefix: "zmy_"
  # List dependencies (other generated files this protocol imports):
  dependencies:
    - stable/xdg-shell/xdg_shell.dart
```

3. Run the scanner:

```bash
dart run bin/scanner.dart scan --protocols=protocols.yaml
```

4. Export the new protocol from `lib/wayland.dart`:

```dart
export 'protocols/staging/my-protocol/my_protocol_v1.dart';
```

### Protocol Cache

XML files are cached in `.wayland-protocol-cache/` to avoid re-downloading.
Use `--force` to bypass the cache and fetch fresh copies.

## Development

### Prerequisites

- Dart SDK >= 3.8.0
- Wayland compositor running (for tests/examples)

### Setup

```bash
dart pub get
```

### Regenerate Protocols

```bash
dart run bin/scanner.dart scan --protocols=protocols.yaml --force
```

### Run Examples

```bash
cd example
dart pub get
dart run bin/wayland2.dart
```

## Architecture

The library has three layers:

1. **Core Protocol** (`lib/src/protocol/`) — Unix socket I/O (`Context`, `UnixSocket`),
   message serialization, proxy management, shared memory helpers (`mmapFd`, `writeToFd`,
   `createAnonymousFile`).

2. **Generated Bindings** (`lib/protocols/`) — One Dart file per Wayland protocol XML.
   Each file contains classes for every interface in the protocol (requests, events,
   enums). Generated by `bin/scanner.dart`.

3. **Scanner** (`lib/src/scanner/`) — XML parser + Dart code generator that reads
   Wayland protocol XML and produces the bindings.

## API Overview

### Core Types

| Class | Description |
|-------|-------------|
| `Context` | Manages the Wayland display socket connection and event dispatch |
| `Proxy` | Base class for all Wayland proxy objects |
| `WlDisplay` | Core display object (id=1) |
| `WlRegistry` | Global registry for binding protocol extensions |

### Shared Memory Helpers

```dart
int createAnonymousFile(int size)   // create a memfd-backed file
void writeToFd(int fd, Uint8List)   // mmap + write + munmap
void closeFd(int fd)                // safe close (guards -1)
Pointer<Void> mmapFd(int fd, int size)  // mmap with validation
void munmap(Pointer<Void>, int size)    // unmap
```

### Error Handling

All Wayland requests return `Result<T, Object>` from `package:result_dart`:

```dart
final surface = compositor.createSurface().getOrElse((e) {
  stderr.writeln('Failed: $e');
  return WlSurface(context);
});
```

## License

MIT
