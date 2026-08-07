import 'package:bardash/src/config.dart';
import 'package:bardash/src/metrics.dart';
import 'package:bardash/src/modules/cpu.dart';
import 'package:bardash/src/modules/memory.dart';

void main() {
  final cfg = BardashConfig()..metrics = BarMetrics.compact;
  cfg.applyMetrics();

  final cpu = CpuModule();
  cpu.init({
    'format': '/ C {usage}%',
    'on-click': 'echo CPU_CLICK',
    'on-click-right': 'echo CPU_RIGHT',
  });
  print('cpu hasClick=${cpu.hasClick} cmd="${cpu.onClickCmd}"');
  // Don't actually spawn ghostty — just verify the default path is live.
  // onClick will try runBarCommand; empty is no-op, non-empty starts process.
  final mem = MemoryModule();
  mem.init({
    'format': '/ M {percent}%',
    'on-click': 'true', // no-op shell builtin, exits immediately
  });
  print('mem hasClick=${mem.hasClick} cmd="${mem.onClickCmd}"');
  mem.onClick(0, 0);
  print('mem onClick invoked (runBarCommand true)');
  // Ensure base method is not empty — CpuModule must not override to no-op
  print('cpu runtime type onClick: ${cpu.onClick}');
}
