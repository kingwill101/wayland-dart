/// Pre-configured custom modules that mirror the user's waybar config.
///
/// Each sets [CustomModule] defaults for `exec`, `on-click`, etc. so they
/// work out of the box in a bardash Lua config without per-module options.
library;

import 'custom.dart';

/// `custom/appmenu` — Rofi application launcher.
class AppMenuModule extends CustomModule {
  @override
  String get name => 'custom/appmenu';

  @override
  void init(Map<String, String> config) {
    final c = Map<String, String>.from(config);
    c.putIfAbsent('exec', () => "echo Apps");
    c.putIfAbsent('on-click', () => "rofi -show drun -replace");
    super.init(c);
  }
}

/// `custom/exit` — WLogout power menu.
class ExitModule extends CustomModule {
  @override
  String get name => 'custom/exit';

  @override
  void init(Map<String, String> config) {
    final c = Map<String, String>.from(config);
    c.putIfAbsent('exec', () => "echo '\u{f011}'");
    c.putIfAbsent('on-click', () => "wlogout -b 4");
    super.init(c);
  }
}

/// `custom/system` — System settings icon.
class SystemModule extends CustomModule {
  @override
  String get name => 'custom/system';

  @override
  void init(Map<String, String> config) {
    final c = Map<String, String>.from(config);
    c.putIfAbsent('exec', () => "echo '\u{f0ad}'");
    super.init(c);
  }
}

/// `custom/quicklinks` — Row of launcher icons (simulated as a single
/// custom module showing an icon; click opens the first quicklink).
class QuicklinksModule extends CustomModule {
  @override
  String get name => 'custom/quicklinks';

  @override
  void init(Map<String, String> config) {
    final c = Map<String, String>.from(config);
    c.putIfAbsent('exec', () => "echo '\u{f0c1}'");
    c.putIfAbsent(
      'on-click',
      () => "~/.config/ml4w/apps/ML4W_Hyprland_Settings-x86_64.AppImage",
    );
    super.init(c);
  }
}
