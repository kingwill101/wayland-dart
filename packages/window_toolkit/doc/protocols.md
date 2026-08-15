# Wayland protocol capabilities

`WaylandConnection` keeps the core objects needed to create toolkit windows
and exposes optional compositor protocols through `connection.protocols` and
`connection.services`.

Optional protocols are bound only when the compositor advertises them. This is
important for applications that run on both wlroots compositors and desktop
compositors such as Mutter or KWin.

## Common services

```dart
final services = connection.services!;

services.workspaces.workspaces;
services.foreignToplevels.toplevels;
services.activation.requestToken(appId: 'com.example.App');
services.clipboard.device(connection.seat);
services.idle.inhibit(surface);
services.capture.captureOutput(connection.output);
```

The protocol registry also provides typed access for capabilities that do not
yet have a higher-level helper:

```dart
final fifo = connection.protocols?.get<WpFifoManagerV1>('wp_fifo_manager_v1');
final dmabuf = connection.protocols?.get<ZwpLinuxDmabufV1>('zwp_linux_dmabuf_v1');
```

## Capability groups

| Group | Protocols | Toolkit surface |
| --- | --- | --- |
| Outputs and scaling | `wl_output`, `xdg-output-v1`, `fractional-scale-v1`, `viewporter` | connection output globals and protocol registry |
| Workspaces and windows | `ext-workspace-v1`, `foreign-toplevel-management-v1`, `xdg-activation-v1` | `services.workspaces`, `services.foreignToplevels`, `services.activation` |
| Clipboard | `wl_data_device`, `primary-selection-v1`, `ext-data-control-v1`, `wlr-data-control` | `services.clipboard` |
| Frame pacing and buffers | `presentation-time`, `fifo-v1`, commit timing, tearing control, linux-dmabuf, explicit sync | typed optional managers |
| Input | relative pointer, pointer constraints, gestures, tablet, cursor shape, text input, shortcut inhibition | `services.input` |
| Idle and power | idle inhibit, ext-idle-notify, output power, gamma, input inhibitor | `services.idle` and typed optional managers |
| Capture | ext image capture source/copy capture, screencopy, export-dmabuf | `services.capture` |
| Security and session | session lock, security context, transient seat | typed optional managers |
| Display specialization | DRM lease, output management, color management, color representation, background effect | typed optional managers |

## Server-created child objects

Some protocols announce child objects in events. The generated bindings now
support `Context.adoptProxy`, which lets toolkit services attach the generated
Dart proxy to the compositor-assigned object ID before registering listeners.
This keeps event dispatch and typed requests on the same proxy path.
