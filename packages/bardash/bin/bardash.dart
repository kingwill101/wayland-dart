import 'dart:io';

import 'package:bardash/bardash.dart';
import 'package:window_toolkit/window_toolkit.dart';

Future<void> main(List<String> args) async {
  // Config priority: CLI arg > ~/.config/bardash/config.lua > inline default
  String? configPath;
  if (args.isNotEmpty) {
    configPath = args[0];
  } else {
    final home = Platform.environment['HOME'] ?? '/home/kingwill101';
    final defaultPath = '$home/.config/bardash/config.lua';
    if (File(defaultPath).existsSync()) {
      configPath = defaultPath;
    }
  }

  BardashConfig config;
  if (configPath != null) {
    config = await BardashConfig.fromFile(configPath);
  } else {
    config = await BardashConfig.fromLua('''
      position = "top"
      density = "normal"
      icon_font_family = "Noto Color Emoji"
      modules_left = { "hyprland/workspaces", "hyprland/window" }
      modules_center = { "clock" }
      modules_right = { "hyprland/language", "wireplumber", "memory", "network", "battery" }
    ''');
  }

  final bar = BardashBar(config);
  // bar.rendererBackend= RendererBackend.skia;
  await bar.show();
  Application.instance.exec();
}
