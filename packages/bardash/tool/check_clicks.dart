import 'dart:io';
import 'package:bardash/bardash.dart';

void main() async {
  final c = await BardashConfig.fromFile('${Platform.environment['HOME']}/.config/bardash/config.lua');
  c.applyMetrics();
  for (final name in ['custom/quicklink1', 'custom/quicklink2', 'custom/quicklink3', 'group/quicklinks']) {
    print('$name => ${c.moduleConfigs[name]}');
  }
  final mod = createModule('group/quicklinks');
  print('created ${mod.runtimeType}');
  // Use dynamic bind if GroupModule
  try {
    (mod as dynamic).bindFactory(
      allModuleConfigs: c.moduleConfigs,
      iconFontFamily: c.iconFontFamily,
    );
    final cfg = <String, String>{};
    for (final e in c.moduleConfigs['group/quicklinks']!.entries) {
      if (e.value is String) cfg[e.key] = e.value as String;
    }
    mod!.init(cfg);
    final children = (mod as dynamic).contentChildren as List;
    for (final child in children) {
      print('child ${child.runtimeType} onClick="${child.onClickCmd}" tip="${child.tooltip}"');
    }
  } catch (e, st) {
    print('err $e\n$st');
  }
}
