import 'dart:io';
import 'package:bardash/src/config.dart';
import 'package:bardash/src/modules/registry.dart';

void main() async {
  final path = '${Platform.environment['HOME']}/.config/bardash/config.lua';
  final c = await BardashConfig.fromFile(path);
  for (final name in ['cpu', 'memory']) {
    final block = c.moduleConfigs[name]!;
    print('$name cfg=$block');
    final mod = createModule(name)!;
    final modCfg = <String, String>{};
    for (final e in block.entries) {
      if (e.value is String) modCfg[e.key] = e.value as String;
    }
    mod.init(modCfg);
    print('  onClickCmd="${mod.onClickCmd}" hasClick=${mod.hasClick}');
  }
}
