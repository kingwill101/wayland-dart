# Bardash modules

Reference for every module name the bar can load, how it is resolved, common
config keys, format placeholders, and backend (shell / D-Bus / IPC / ffigen).

Config lives in Lua (`modules_left` / `modules_center` / `modules_right` +
`modules_config`). Keys may use underscores in Lua; they are normalized to
**dashed** form (`on_click` → `on-click`).

---

## Module resolution

| Config name | Result |
|-------------|--------|
| Exact key in the registry | That module type |
| `group/…` or `group:…` | Dynamic [`GroupModule`](#group) |
| `custom/…` not otherwise registered | [`CustomModule`](#custom) |
| Unknown | Skipped |

Registered aliases of note:

- **`tray`** → same as **`sni`** (StatusNotifierItem tray)
- **`custom/appmenu`**, **`custom/quicklink*`**, **`custom/exit`**, **`custom/system`** → `CustomModule` with those default names (still configured via `modules_config`)

---

## Common keys (all modules)

Inherited from `BarModule.init` unless a module overrides:

| Key | Default | Meaning |
|-----|---------|---------|
| `padding` | density `modulePad` | Horizontal pad both sides |
| `padding-left` / `padding-right` | from `padding` | Asymmetric pad |
| `margin-left` / `margin-right` | 0 | Outer gap outside hit box |
| `on-click` | — | Left click command (`runBarCommand`) |
| `on-click-right` | — | Right click command |
| `on-scroll-up` / `on-scroll-down` | — | Wheel commands |
| `tooltip-format` | — | Template; modules fill `{placeholders}` when supported |
| `format` | module default | Main display template |
| `format-<state>` | — | Override when module is in that state (waybar-style) |
| `interval` | module default | Poll seconds (`0` = no timer; signal-driven modules still refresh) |
| `color` | — | Text color when the module reads it |
| `icon-font-family` | bar `icon_font_family` | Passed into groups for FA-style icons |

Commands expand a leading `~/` and run via `/bin/sh` (scripts without shebang
work; AppImages work).

---

## Density / layout (not modules)

Bar-level Lua (see `BarMetrics` / `BardashConfig`):

| Key | Role |
|-----|------|
| `density` | `compact` \| `normal` \| `comfortable` |
| `spacing` | Gap between top-level modules |
| `height` / `exclusive_zone` | Layer height |
| `icon_font_family` | FA / Nerd font role |
| `position` | `top` \| `bottom` |

---

## Hyprland

### `hyprland/workspaces`

| | |
|--|--|
| **Backend** | Hyprland socket IPC (`hyprctl` fallback) |
| **Default format** | `{name}` |
| **Interval** | 1s |
| **UI** | `Button` + `HBox` (click switches workspace) |

**Placeholders:** `{name}`, `{id}` (as exposed by IPC rebuild).

**Config:** standard padding; format string.

---

### `hyprland/window`

| | |
|--|--|
| **Backend** | Hyprland IPC active window |
| **Default format** | `{title}` |
| **Interval** | 1s |
| **Config** | `max-width` (px, default `200`) |

**Placeholders:** `{title}`, `{class}`.

Empty title measures as zero width (no reserved hole).

---

### `hyprland/language`

| | |
|--|--|
| **Backend** | Hyprland IPC |
| **Default format** | `{short}` |
| **Interval** | 1s |

**Placeholders:** `{short}`, and other fields returned by the language query as
wired in the module.

---

### `hyprland/submap`

| | |
|--|--|
| **Backend** | Hyprland IPC |
| **Default format** | `{icon}` |
| **Interval** | 1s |

**Placeholders:** `{icon}`, submap name. Optional icon map via config keys named
after submaps. Empty when on default submap (`format-default`).

---

### `hyprland/windowcount`

| | |
|--|--|
| **Backend** | Hyprland IPC |
| **Default format** | `{icon} {count}` |
| **Interval** | 1s |

**Placeholders:** `{icon}`, `{count}`.

---

## Sway

### `sway/workspaces`

| | |
|--|--|
| **Backend** | `swaymsg` / IPC-style updates |
| **Default format** | `{name}` |
| **Interval** | 1s |
| **UI** | Custom workspace buttons |

---

### `sway/window`

| | |
|--|--|
| **Default format** | `{title}` |
| **Interval** | 1s |
| **Config** | `truncate` (chars, `0` = off) |

**Placeholders:** `{title}`, `{app_id}`.

---

### `sway/language`

| | |
|--|--|
| **Default format** | `{short}` |
| **Interval** | 1s |

**Placeholders:** `{short}` (and related layout fields as implemented).

---

### `sway/mode`

| | |
|--|--|
| **Default format** | `{mode}` |
| **Interval** | 1s |

Hides or uses `format-default` when mode is default.

---

## Audio

### `wireplumber` (preferred)

| | |
|--|--|
| **Backend** | Async `wpctl` (+ optional PipeWire shim) |
| **Default format** | `{icon} {volume}% {format_source}` |
| **Interval** | 2s |

**Placeholders:** `{volume}`, `{icon}`, `{muted}`, `{format_source}`,
`{source_volume}`, `{source_icon}`, `{node_name}`.

**Config:**

| Key | Default | Notes |
|-----|---------|--------|
| `format-source` | `{source_volume}% …` | Mic line (avoid embedding emoji; module draws icons separately) |
| `format-source-muted` | muted glyph | |
| `scroll-step` | `5` | Volume step % |
| Left click | mute toggle | Unless `on-click` set |
| Scroll | volume up/down | |

Icons use **Noto Color Emoji** layout slots so text is not drawn under the speaker.

---

### `pulseaudio` / `volume`

| | |
|--|--|
| **Backend** | Shell (`pactl` / similar) |
| **Default format** | `{volume}% {icon}` / `Vol {volume}%` |
| **Interval** | 2s |

Prefer **`wireplumber`** on PipeWire systems.

---

### `pulseaudio-slider` / `backlight-slider`

| | |
|--|--|
| **UI** | Drawn bar + icon/percent |
| **Config** | `bar-width`, `bar-height`, `bar-color`, `bar-bg-color`, `device` (backlight) |
| **Interval** | 2–3s |

---

### `mpd`

| | |
|--|--|
| **Backend** | **ffigen** `libmpdclient` (fallback `mpc`) |
| **Default format** | `{artist} - {title}` |
| **Interval** | 3s |

**Placeholders:** `{artist}`, `{title}`, `{album}`, `{elapsed}`, `{total}`,
`{state}`, `{volume}`, `{icon}`.

**Config:** `host` (`127.0.0.1`), `port` (`6600`), `max-length`,
`format-paused`, `format-stopped` (empty = hide).

---

### `mpris`

| | |
|--|--|
| **Backend** | **D-Bus** session (`org.mpris.MediaPlayer2.*`) |
| **Default format** | `{icon} {artist} - {title}` |
| **Interval** | 15s (signals drive most updates) |

**Placeholders:** `{artist}`, `{title}`, `{album}`, `{status}`, `{icon}`,
`{player}`.

**Config:** `max-length` (default `40`), `format-paused`, `format-stopped`
(empty hides).

**Input:** left click play/pause; scroll next/previous; middle next.

---

## System / hardware

### `cpu`

| | |
|--|--|
| **Backend** | `/proc/stat` |
| **Default format** | `{usage}%` |
| **Interval** | 2s |

**Placeholders:** `{usage}`.

---

### `cpu-usage`

Same idea as `cpu`, default interval **1s**.

---

### `cpu-frequency`

| | |
|--|--|
| **Default format** | `{freq} MHz` |
| **Interval** | 2s |

**Placeholders:** `{freq}`.

---

### `cpu/graph`

| | |
|--|--|
| **UI** | Sparkline of CPU usage |
| **Config** | `graph-width`, `graph-height`, `samples`, `color` |
| **Interval** | 1s |

---

### `memory`

| | |
|--|--|
| **Backend** | `/proc/meminfo` |
| **Default format** | `{percent}%` |
| **Interval** | 3s |

**Placeholders:** `{percent}`, used/total fields as implemented in `update`.

---

### `battery`

| | |
|--|--|
| **Backend** | **D-Bus** UPower (signals) + sysfs `BAT*` fallback |
| **Default format** | `{capacity}%{icon}` |
| **Interval** | 15s (signals primary) |
| **Config** | `bat` (default `BAT0`, matches UPower `NativePath`) |

**Placeholders:** `{capacity}`, `{status}`, `{icon}`, `{time}`, `{model}`
(emoji; charging ⚡).

Icons measured with **Noto Color Emoji** + `iconTextGap`.

---

### `upower`

| | |
|--|--|
| **Backend** | **D-Bus** UPower device list (signals; no `upower` CLI) |
| **Default format** | `{percentage}% {icon}` |
| **Interval** | 30s (signals primary) |
| **Config** | `device` (native path / path fragment filter) |

**Placeholders:** `{percentage}`, `{state}`, `{time}`, `{icon}`, `{model}`.

---

### `backlight`

| | |
|--|--|
| **Backend** | sysfs `/sys/class/backlight` |
| **Default format** | `☀ {percent}%` |
| **Interval** | 3s |

---

### `temperature`

| | |
|--|--|
| **Backend** | sysfs `/sys/class/thermal` |
| **Default format** | `{temp}°C` |
| **Interval** | 5s |
| **Config** | `thermal_zone` / path selection |

---

### `disk`

| | |
|--|--|
| **Backend** | libc **`statvfs`** (no `df`) |
| **Default format** | `Disk {used_pct}%` |
| **Interval** | 10s |
| **Config** | `path` (mount point, default `/`) |

**Placeholders:** `{used_pct}`, `{total}`, `{used}`, `{avail}`, `{path}`
(human sizes like `df -h`).

---

### `load`

| | |
|--|--|
| **Backend** | `/proc/loadavg` |
| **Default format** | `Load {avg1}` |
| **Interval** | 5s |

**Placeholders:** `{avg1}`, `{avg5}`, `{avg15}`.

---

### `network`

| | |
|--|--|
| **Backend** | **D-Bus** NetworkManager (+ signals) |
| **Default format** | `{ipaddr}` |
| **Interval** | 30s (signals primary) |

**Placeholders:** `{ipaddr}`, `{ifname}`, `{essid}`, `{signalStrength}`,
`{signal}`, `{icon}`.

**Formats:** `format`, `format-wifi`, `format-ethernet`, `format-disconnected`.

**Default click:** `nm-connection-editor` (or `on-click`).

---

### `bluetooth`

| | |
|--|--|
| **Backend** | **D-Bus** BlueZ ObjectManager (+ signals) |
| **Default format** | ` {device_count}` |
| **Interval** | 30s |

**Placeholders:** `{icon}`, `{power}`, `{device_count}`, `{device}`,
`{devices}`, `{adapter}`.

**States:** `off`, `on`, `connected` → `format-off`, etc.

**Default click:** `blueman-manager`.

---

### `privacy`

| | |
|--|--|
| **Backend** | V4L2 sysfs + async `pactl` source-outputs (light; no heavy sync shell) |
| **Default format** | `{icon}` |
| **Interval** | 3s |

**Placeholders:** `{camera}`, `{mic}`, `{icon}`, `{icon-camera}`, `{icon-mic}`.

Hides when neither camera nor mic is active.

---

### `gamemode`

| | |
|--|--|
| **Backend** | `$XDG_RUNTIME_DIR/gamemode/client.count` then session **D-Bus**
`com.feralinteractive.GameMode` (no `gamemoded -s`) |
| **Default format** | `{icon}` |
| **Interval** | 5s |

**Placeholders:** `{count}`, `{icon}`; `format-active`.

Hides when GameMode is not available.

---

### `inhibitor` / `idle-inhibitor`

| | |
|--|--|
| **Backend** | Local toggle (+ optional `on-click` command) |
| **Default format** | `{icon}` |

**Config:** `format-activated`, `format-deactivated`.

Note: does not yet bind a real Wayland idle-inhibit surface; state is UI + command.

---

### `power-profiles-daemon`

| | |
|--|--|
| **Backend** | **D-Bus** `org.freedesktop.UPower.PowerProfiles` or
`net.hadess.PowerProfiles` (no `powerprofilesctl`) |
| **Default format** | `{icon}` |
| **Interval** | 30s (signals primary) |

**Placeholders:** `{profile}`, `{icon}`. Profile name drives
`format-<profile>`. Left click cycles profiles (or `on-click`).

Hides when the daemon is not installed.

---

### `systemd-failed`

| | |
|--|--|
| **Backend** | **D-Bus** systemd Manager (`NFailedUnits` +
`ListUnitsFiltered`; no `systemctl`) |
| **Default format** | ` {count}` |
| **Interval** | 60s (property signals primary) |

**Placeholders:** `{count}`, `{icon}`, `{units}`. Hides when count is 0.

---

### `keyboard-state`

| | |
|--|--|
| **Backend** | sysfs `/sys/class/leds` (caps/num lock) |
| **Default format** | `{name}` |
| **Interval** | 2s |
| **Config** | `capslock=true`, `numlock=true` |

---

### `user`

| | |
|--|--|
| **Backend** | env + `Platform.localHostname` (no `whoami` / `hostname`) |
| **Default format** | `{user}` |
| **Interval** | 3600s |

**Placeholders:** `{user}`, `{hostname}`, `{home}`.

---

### `wwan`

| | |
|--|--|
| **Backend** | **D-Bus** ModemManager ObjectManager (no `mmcli`) |
| **Default format** | `{icon} {signal}%` |
| **Interval** | 30s (signals primary) |
| **Config** | `modem-index` |

**Placeholders:** `{state}`, `{signal}`, `{operator}`, `{technology}`,
`{imei}`, `{icon}`. Hides when no modem.

---

### `gps`

| | |
|--|--|
| **Backend** | **D-Bus** GeoClue2 client (no `gpspipe`) |
| **Default format** | `{lat},{lon}` |
| **Interval** | 30s (LocationUpdated signals) |

**Placeholders:** `{lat}`, `{lon}`, `{altitude}`, `{speed}`, `{fix}`,
`{icon}`, `{accuracy}`, `{description}`. Hides without a fix.

---

## Clock & tray

### `clock`

| | |
|--|--|
| **Default format** | `%H:%M` (strftime-like tokens) |
| **Interval** | 1s |
| **Config** | `calendar=false` to disable calendar tooltip |

**Tooltip:** multi-line calendar by default; `tooltip-format` may include
`{calendar}`.

---

### `tray` / `sni`

| | |
|--|--|
| **Backend** | StatusNotifierWatcher + item D-Bus; IconTheme / IconPixmap |
| **Interval** | 10s (icons also push updates) |
| **Config** | `max-icons` (default `8`) |

**Features:** per-icon tooltips, left/right click, dbusmenu context menus on
layer-shell overlay, scroll where the item supports it.

---

### `separator`

| | |
|--|--|
| **Config** | `format` / `text` (glyph), `color`, `padding` |

Used inside groups or alone as a divider.

---

### `image`

| | |
|--|--|
| **Config** | `path`, `size` (default 16), `interval` |

Draws a PNG/JPEG (or placeholder if missing).

---

## Custom & groups

### `custom` and `custom/*`

| Mode | Behavior |
|------|----------|
| **Static** | `format` set, no `exec` → fixed label |
| **Exec** | `exec` shell command every `interval` (default 5s) |

**Config:** `format`, `exec`, `interval`, `color`, `tooltip-format`,
`on-click`, `on-click-right`.

Short `format` (≤2 runes) is treated as an **icon** (fixed icon slot + icon
font). Longer text uses the UI font and advance-based width.

Registered convenience names (`custom/appmenu`, `custom/quicklink1`–`3`,
`custom/exit`, …) are still plain `CustomModule` instances.

---

### `custom/graph`

| | |
|--|--|
| **Backend** | Shell `exec`, parse number |
| **Config** | `exec`, `pattern`, `min`, `max`, `graph-width`, `graph-height`, `samples`, `color` |
| **Interval** | 5s |

**Placeholders:** `{value}`.

---

### `group/*` (dynamic)

| | |
|--|--|
| **Config** | `modules` (comma/space list of child names) |
| | `separator` (string; `""` allowed) |
| | `item-spacing` / `spacing` → HBox gap (default density `groupChildPad`) |
| | `child-padding` (default `0`) |
| | `background` (optional fill) |
| | outer `padding-*` on the group itself |

Children load their own `modules_config` blocks. Clicks and tooltips resolve to
the child under the pointer (absolute X hit-test).

Example:

```lua
modules_left = { "custom/appmenu", "group/quicklinks" }

modules_config = {
  ["group/quicklinks"] = {
    modules = "custom/quicklink1,custom/quicklink2,custom/quicklink3",
    separator = "",
    ["item-spacing"] = "6",
  },
  ["custom/quicklink1"] = {
    format = "",
    on_click = "~/.config/ml4w/apps/ML4W_Hyprland_Settings-x86_64.AppImage",
    ["tooltip-format"] = "Hyprland Settings",
  },
}
```

---

## Backend summary

| Backend | Modules |
|---------|---------|
| **Hyprland IPC (ffi socket)** | `hyprland/*` |
| **D-Bus (system)** | `bluetooth` (BlueZ), `network` (NetworkManager), `battery`/`upower` (UPower), `power-profiles-daemon`, `systemd-failed`, `wwan` (ModemManager), `gps` (GeoClue2) |
| **D-Bus (session)** | `mpris`, `tray`/`sni`, `gamemode` (optional GameMode) |
| **ffigen / libc** | `mpd` (libmpdclient), `disk` (`statvfs`), PipeWire shim for wireplumber paths |
| **sysfs / proc** | `cpu*`, `memory`, `load`, `temperature`, `backlight`, `keyboard-state`, battery sysfs fallback, privacy V4L2 |
| **Async / sync shell** | `wireplumber` (`wpctl`), `pulseaudio` (`pactl`), sway modules (`swaymsg`), custom `exec` |
| **Platform / env** | `user` |
| **UI only + command** | `idle-inhibitor` / `inhibitor`, pure custom labels |

Native clients live under `lib/src/native/` (`*_client.dart`, `statvfs.dart`, `hyprland_ipc.dart`, …).

---

## Gaps / depth notes (for implementers)

- Prefer **D-Bus, IPC, or libc** over `Process.runSync` for anything on a 1–2s interval.
- **Styling** (module backgrounds, hover, CSS-like rules) is not module-specific yet.
- **Idle inhibitor** is not bound to `zwp_idle_inhibit` / logind yet.
- **wireplumber / pulseaudio** still poll `wpctl`/`pactl`; deepen via PipeWire/Pulse FFI next.
- **privacy** mic path still uses light async `pactl`; portal/`pw` node graph would be cleaner.
- **Multi-output** bars are not yet multi-instance per connector.

---

## Listing modules at runtime

```dart
import 'package:bardash/bardash.dart';

print(availableModules);
```

Or inspect `lib/src/modules/registry.dart` for the canonical name → constructor map.
