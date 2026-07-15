# Wayland Example

Minimal working example of a Wayland client using the `package:wayland` Dart library.

## Running

```bash
cd packages/wayland/example
dart pub get
dart run bin/wayland2.dart
```

This opens a simple 800×600 Wayland window with a white background.
Requires a running Wayland compositor (sway, Hyprland, river, etc.).
