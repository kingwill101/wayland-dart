import 'package:bardash/src/modules/cpu.dart';
import 'package:bardash/src/modules/memory.dart';
import 'package:bardash/src/config.dart';
import 'package:bardash/src/metrics.dart';

void main() async {
  final cfg = BardashConfig()..metrics = BarMetrics.compact;
  cfg.applyMetrics();

  final cpu = CpuModule();
  cpu.init({'interval': '1', 'format': '/ C {usage}%'});
  print('cpu1 out="${cpu.output}" tip:\n${cpu.tooltip}\n---');
  await Future<void>.delayed(const Duration(milliseconds: 200));
  cpu.update();
  print('cpu2 out="${cpu.output}" tip:\n${cpu.tooltip}\n---');

  final mem = MemoryModule();
  mem.init({'interval': '3', 'format': '/ M {percent}%'});
  print('mem out="${mem.output}" tip:\n${mem.tooltip}');
}
