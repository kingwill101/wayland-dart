import 'package:test/test.dart';
import 'package:window_toolkit/window_toolkit.dart';

void main() {
  test('RecordingPainter golden: bar-like draw sequence', () {
    final p = RecordingPainter(width: 320, height: 30);
    p.clear(const Color(30,30,30));
    p.drawRect(Rect.fromLTWH(0,0,320,30), Paint()..color=const Color(43,48,59));
    p.drawRRect(Rect.fromLTWH(10,5,80,20), 6, 6, Paint()..color=const Color(100,100,120));
    p.drawCircle(const Offset(280,15), 10, Paint()..color=const Color(0,200,0));
    p.drawText('12:34', const Offset(140,8), color: const Color(255,255,255), size:14);
    // Golden expectations: command count and order
    expect(p.commands.length, 5);
    expect(p.commands[0], isA<ClearCommand>());
    expect(p.commands[1], isA<DrawRectCommand>());
    expect(p.commands[2], isA<DrawRectCommand>()); // RRect falls back to DrawRect in RecordingPainter
    expect(p.commands[3], isA<DrawCircleCommand>());
    expect(p.commands[4], isA<DrawTextCommand>());
    final txt = p.commands[4] as DrawTextCommand;
    expect(txt.text, '12:34');
    expect(txt.color?.r, 255);
  });
  test('RecordingPainter golden: gradient + image', () {
    final p = RecordingPainter(width: 100, height: 50);
    p.drawLinearGradient(Rect.fromLTWH(0,0,100,10), const Color(255,0,0), const Color(0,0,255));
    p.drawImage('/tmp/fake.png', 10, 10, width: 20, height: 20);
    expect(p.commands.whereType<DrawLinearGradientCommand>().single.color0.r, 255);
    expect(p.commands.whereType<DrawImageCommand>().single.filePath, '/tmp/fake.png');
  });
}
