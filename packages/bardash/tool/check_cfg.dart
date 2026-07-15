import 'dart:io';

import 'package:bardash/bardash.dart';

void main() async {
  final c = await BardashConfig.fromFile(
    '${Platform.environment['HOME']}/.config/bardash/config.lua',
  );
  print(
    'density=${c.metrics.name} spacing=${c.spacing} '
    'pad=${c.metrics.modulePad} iconSlot=${c.metrics.iconSlot}',
  );
  final g = c.moduleConfigs['group/quicklinks'];
  print('group cfg: $g');
  print(
    'separator key? ${g?.containsKey('separator')} '
    'value=${g?['separator']?.runtimeType} "${g?['separator']}"',
  );
  print('appmenu: ${c.moduleConfigs['custom/appmenu']}');
  print('q1: ${c.moduleConfigs['custom/quicklink1']}');
}
