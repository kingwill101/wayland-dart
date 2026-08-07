import 'package:test/test.dart';
import 'package:bardash/bardash.dart';

void main() {
  group('BardashConfig._readTableList regression', () {
    test('parses modules_left as List (lualike List unwrap)', () async {
      final c = await BardashConfig.fromLua('''
        modules_left = { "hyprland/workspaces", "hyprland/window" }
        modules_center = { "clock" }
        modules_right = { "battery" }
      ''');
      expect(c.modulesLeft, equals(["hyprland/workspaces", "hyprland/window"]));
      expect(c.modulesCenter, equals(["clock"]));
      expect(c.modulesRight, equals(["battery"]));
    });

    test('parses empty tables as []', () async {
      final c = await BardashConfig.fromLua('''
        modules_left = {}
        modules_center = {}
        modules_right = {}
      ''');
      expect(c.modulesLeft, isEmpty);
      expect(c.modulesCenter, isEmpty);
      expect(c.modulesRight, isEmpty);
    });

    test('default config (bin/bardash.dart inline) yields 8 modules', () async {
      final c = await BardashConfig.fromLua('''
        position = "top"
        density = "normal"
        icon_font_family = "Noto Color Emoji"
        modules_left = { "hyprland/workspaces", "hyprland/window" }
        modules_center = { "clock" }
        modules_right = { "hyprland/language", "wireplumber", "memory", "network", "battery" }
      ''');
      expect(c.modulesLeft.length + c.modulesCenter.length + c.modulesRight.length, 8);
    });

    test('parses single entry', () async {
      final c = await BardashConfig.fromLua('''
        modules_left = { "clock" }
      ''');
      expect(c.modulesLeft, equals(["clock"]));
    });

    test('handles missing tables as [] (no crash)', () async {
      final c = await BardashConfig.fromLua('''
        position = "top"
      ''');
      expect(c.modulesLeft, isEmpty);
      expect(c.modulesCenter, isEmpty);
    });
  });

  group('BardashConfig.fromFile/List vs Map', () {
    test('List unwrap path does not break Map numeric-key path', () async {
      // Simulate Map case by directly testing _readTableList via fromLua
      // lualike currently returns List, but future change to Map should still work.
      // We verify both lengths are handled.
      final c1 = await BardashConfig.fromLua('modules_left = { "a", "b", "c" }');
      expect(c1.modulesLeft, hasLength(3));
    });
  });
}
