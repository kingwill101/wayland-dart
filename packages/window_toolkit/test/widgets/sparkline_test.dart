import 'package:test/test.dart';
import 'package:window_toolkit/window_toolkit.dart';

void main() {
  test('sparkline draws one segment per adjacent sample pair', () {
    final sparkline = Sparkline(
      values: const [10, 30, 20],
      width: 30,
      height: 12,
    );
    final painter = RecordingPainter(width: 100, height: 30);
    sparkline.draw(painter);

    expect(painter.commands.whereType<DrawLineCommand>(), hasLength(2));
  });

  test('sparkline accepts live value replacement without relayout', () {
    final sparkline = Sparkline(values: const [1, 2], width: 24, height: 8);
    final painter = RecordingPainter(width: 100, height: 30);
    sparkline.measure(painter);
    sparkline.values = const [1, 4, 2, 8];
    sparkline.measure(painter);

    expect(sparkline.width, 24);
    expect(sparkline.height, 8);
  });
}
