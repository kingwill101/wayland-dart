import 'package:bardash/src/bar_text.dart';
import 'package:bardash/src/config.dart';
import 'package:bardash/src/metrics.dart';
import 'package:bardash/src/modules/custom.dart';
import 'package:bardash/src/modules/memory.dart';
import 'package:window_toolkit/window_toolkit.dart';

void main() {
  final cfg = BardashConfig()
    ..iconFontFamily = 'Hack Nerd Font'
    ..metrics = BarMetrics.compact;
  cfg.applyMetrics();
  print('roles=${FontDatabase.instance.roleFamilies}');
  print('resolved=${BarText.resolveFamily(BarText.iconFamilyCandidates, fallback: "Hack Nerd Font")}');

  final m = MemoryModule();
  m.init({'interval': '3', 'format': '/ M {percent}%', 'padding': '4'});
  print('output="${m.output}" token=${m.layoutToken}');

  final c = CustomModule();
  c.init({'format': '\uf013', 'padding': '3'});
  print('custom glyphs=${BarText.hasIconGlyphs(c.output)} font=${BarText.fontFor(c.output)}');
  final adv = FontDatabase.instance.metrics(BarText.fontFor(c.output)).horizontalAdvance(c.output);
  print('gear adv=$adv');
}
