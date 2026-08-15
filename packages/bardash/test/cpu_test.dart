import 'package:test/test.dart';
import 'package:bardash/src/modules/cpu.dart';

void main() {
  test('cpu tooltip lists total then per-core lines', () {
    final m = CpuModule()..init({});
    m.update(); // first tick: primes deltas
    m.update(); // second tick: real percentages
    expect(m.output, isNot('ERR'));
    expect(m.tooltip, contains('cpu'), reason: 'should list cores');
    final lines = m.tooltip.split('\n');
    expect(lines.length, greaterThan(1), reason: 'total + cores');
    // Waybar order: total first, then cores descending by line order.
    expect(lines.first, startsWith('CPU '));
    int? cores;
    for (final l in lines.skip(1)) {
      final idx = int.tryParse(l.substring(3, l.indexOf(' ')));
      if (idx != null && (cores == null || idx == cores + 1)) cores = idx;
    }
    expect(cores, isNotNull);
  });
}
