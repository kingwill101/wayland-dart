# Dart Wayland Toolkit

Native Wayland client libraries and a composable window toolkit for Dart.
The workspace contains protocol bindings, graphics bindings, a framework-free
layout engine, and the widgets used by Bardash.

## Packages

[![wayland](https://img.shields.io/pub/v/wayland.svg)](https://pub.dev/packages/wayland)
[![gl](https://img.shields.io/pub/v/gl.svg)](https://pub.dev/packages/gl)
[![layout_engine](https://img.shields.io/pub/v/layout_engine.svg)](https://pub.dev/packages/layout_engine)

| Package | Description | Status |
| --- | --- | --- |
| [`wayland`](https://pub.dev/packages/wayland) | Wayland protocol bindings and client APIs for Dart. | Published |
| [`gl`](https://pub.dev/packages/gl) | OpenGL, OpenGL ES, EGL, GLEW, and GLUT FFI bindings. | Published |
| [`layout_engine`](https://pub.dev/packages/layout_engine) | Framework-independent constraints, render objects, flex, scrolling, and tree utilities. | Published |
| [`window_toolkit`](packages/window_toolkit) | Stateful widgets, CSS styling, input routing, popups, and Wayland window hosting. | Unreleased |
| [`bardash`](packages/bardash) | A customizable Wayland bar built with `window_toolkit` and Lua. | Private application |
| [`window_toolkit_test`](packages/window_toolkit_test) | Test helpers and harnesses for toolkit widgets. | Private development package |

## Getting started

For a Wayland client, add the published package to your application:

```yaml
dependencies:
  wayland: ^1.0.0
```

For layout-only applications:

```yaml
dependencies:
  layout_engine: ^0.1.0
```

See the package READMEs and examples for API-specific setup:

- [`wayland`](packages/wayland/README.md)
- [`gl`](packages/gl/README.md)
- [`layout_engine`](packages/layout_engine/README.md)
- [`window_toolkit`](packages/window_toolkit/README.md)

## Workspace development

This repository is a Dart workspace. From the repository root:

```sh
dart pub get
dart test packages/wayland/test packages/gl/test packages/layout_engine/test
dart test packages/window_toolkit/test packages/bardash/test
```

The current toolkit development branch uses pinned Git revisions of
`skia_dart` and `dawn_dart` so it can use their native Dawn/Graphite support.
`window_toolkit` will be published once those dependencies have usable hosted
releases rather than placeholder packages on pub.dev.

## License

The workspace is released under the [MIT License](LICENSE).
