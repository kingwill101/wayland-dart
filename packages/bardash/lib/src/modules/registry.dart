import 'module.dart';
import 'backlight.dart';
import 'battery.dart';
import 'bluetooth.dart';
import 'clock.dart';
import 'mpris.dart';
import 'cpu.dart';
import 'cpu_frequency.dart';
import 'custom.dart';
import 'disk.dart';
import 'group.dart';
import 'idle_inhibitor.dart';
import 'keyboard_state.dart';
import 'load.dart';
import 'memory.dart';
import 'network.dart';
import 'power_profiles.dart';
import 'separator.dart';
import 'sway_workspaces.dart';
import 'systemd_failed.dart';
import 'temperature.dart';
import 'upower.dart';
import 'user.dart';
import 'pulseaudio.dart';
import 'cpu_usage.dart';
import 'volume.dart';
import 'wireplumber.dart';
import 'mpd.dart';
import 'sway_window.dart';
import 'sway_language.dart';
import 'sway_mode.dart';
import 'gamemode.dart';
import 'inhibitor.dart';
import 'cpu_graph.dart';
import 'custom_graph.dart';
import 'privacy.dart';
import 'wwan.dart';
import 'gps.dart';
import 'pulseaudio_slider.dart';
import 'backlight_slider.dart';
import 'sni.dart';
import 'image.dart';
import 'hyprland_workspaces.dart';
import 'hyprland_window.dart';
import 'hyprland_language.dart';
import 'hyprland_submap.dart';
import 'hyprland_windowcount.dart';

typedef ModuleConstructor = BarModule Function();

final Map<String, ModuleConstructor> _registry = {
  'backlight': () => BacklightModule(),
  'bluetooth': () => BluetoothModule(),
  'clock': () => ClockModule(),
  'battery': () => BatteryModule(),
  'cpu': () => CpuModule(),
  'cpu-frequency': () => CpuFrequencyModule(),
  'disk': () => DiskModule(),
  'memory': () => MemoryModule(),
  'mpris': () => MprisModule(),
  'pulseaudio': () => PulseaudioModule(),
  'cpu-usage': () => CpuUsageModule(),
  'volume': () => VolumeModule(),
  'network': () => NetworkModule(),
  'custom': () => CustomModule(),
  'temperature': () => TemperatureModule(),
  'load': () => LoadModule(),
  'upower': () => UPowerModule(),
  'user': () => UserModule(),
  'idle-inhibitor': () => IdleInhibitorModule(),
  'keyboard-state': () => KeyboardStateModule(),
  'power-profiles-daemon': () => PowerProfilesModule(),
  'systemd-failed': () => SystemdFailedModule(),
  'sway/workspaces': () => SwayWorkspacesModule(),
  'sway/window': () => SwayWindowModule(),
  'sway/language': () => SwayLanguageModule(),
  'sway/mode': () => SwayModeModule(),
  'wireplumber': () => WireplumberModule(),
  'mpd': () => MpdModule(),
  'gamemode': () => GamemodeModule(),
  'inhibitor': () => InhibitorModule(),
  'cpu/graph': () => CpuGraphModule(),
  'custom/graph': () => CustomGraphModule(),
  'privacy': () => PrivacyModule(),
  'wwan': () => WwanModule(),
  'gps': () => GpsModule(),
  'pulseaudio-slider': () => PulseaudioSliderModule(),
  'backlight-slider': () => BacklightSliderModule(),
  // Waybar names the system tray "tray"; we implement StatusNotifierItem as sni.
  'sni': () => SniModule(),
  'tray': () => SniModule(),
  'separator': () => SeparatorModule(),
  'image': () => ImageModule(),
  'hyprland/workspaces': () => HyprlandWorkspacesModule(),
  'hyprland/window': () => HyprlandWindowModule(),
  'hyprland/language': () => HyprlandLanguageModule(),
  'hyprland/submap': () => HyprlandSubmapModule(),
  'hyprland/windowcount': () => HyprlandWindowCountModule(),
  'custom/appmenu': () => CustomModule(),
  'custom/quicklinks': () => CustomModule(),
  'custom/quicklink1': () => CustomModule(),
  'custom/quicklink2': () => CustomModule(),
  'custom/quicklink3': () => CustomModule(),
  'custom/exit': () => CustomModule(),
  'custom/system': () => CustomModule(),
};

BarModule? createModule(String name) {
  final constructor = _registry[name];
  if (constructor != null) return constructor();

  // Dynamic waybar-style groups: "group/sys", "group:hardware", etc.
  if (name.startsWith('group/') || name.startsWith('group:')) {
    return GroupModule(name);
  }

  // Unregistered custom/* modules fall back to CustomModule.
  if (name.startsWith('custom/')) {
    return CustomModule();
  }

  return null;
}

List<String> get availableModules => [
      ..._registry.keys,
      'group/* (dynamic)',
    ];
