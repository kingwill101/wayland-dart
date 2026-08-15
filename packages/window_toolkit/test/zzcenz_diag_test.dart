import 'package:window_toolkit/window_toolkit.dart';
import 'package:test/test.dart';

void main() {
  test('diag geometry', () {
    const cellW = 40, cellH = 24;
    final a = SizedBox(
      width: cellW,
      height: cellH,
      child: DecoratedBox(
        color: const Color(60, 100, 200),
        borderRadius: 8,
        child: Align(child: Label('15', fontSize: 12)),
      ),
    );
    a.x = 0;
    a.y = 0;
    a.performLayout(200);
    final dec = (a as SizedBox).child!;
    final align = (dec as DecoratedBox).child!;
    print('SizedBox   x=${a.x} y=${a.y} w=${a.width} h=${a.height}');
    print('Decorated  x=${dec.x} y=${dec.y} w=${dec.width} h=${dec.height}');
    print(
      'Align      x=${align!.x} y=${align.y} w=${align!.width} h=${align!.height}',
    );
    final lbl = (align as Align).child;
    print('Label      x=${lbl.x} y=${lbl.y} w=${lbl.width} h=${lbl.height}');
    expect(true, isTrue);
  });
}
