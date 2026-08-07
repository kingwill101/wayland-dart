import 'package:bardash/src/native/pulse_client.dart';

void main() async {
  final c = PulseClient.instance;
  c.addListener((s) {
    print('snap sink=${s.sinkPercent}% muted=${s.sinkMuted} source=${s.sourcePercent}%');
  });
  await Future<void>.delayed(const Duration(milliseconds: 400));
  print('available=${c.available} last=${c.last.sinkPercent}');
  c.stepVolume(-5);
  await Future<void>.delayed(const Duration(milliseconds: 200));
  print('after -5: ${c.last.sinkPercent}');
  c.stepVolume(5);
  await Future<void>.delayed(const Duration(milliseconds: 200));
  print('after +5: ${c.last.sinkPercent}');
  await c.dispose();
}
