import 'package:test/test.dart';
import 'package:window_toolkit/window_toolkit.dart';
import 'package:bardash/src/bar_text.dart';
import 'package:bardash/src/metrics.dart';

void main() {
  setUp(() {
    BarMetrics.current = BarMetrics.compact;
    FontDatabase.instance.useBitmapEngine();
  });
  group('BarText', () {
    test('hasIconGlyphs detects PUA', () {
      expect(BarText.hasIconGlyphs('hello'), isFalse);
      expect(BarText.hasIconGlyphs('\uE001'), isTrue); // PUA
      expect(BarText.hasIconGlyphs(''), isTrue); // Nerd Arch
    });
    test('fontFor picks icon for PUA', () {
      final f = BarText.fontFor('\uE001');
      expect(f.role, FontRole.icon);
      final f2 = BarText.fontFor('12:34');
      expect(f2.role, FontRole.ui);
    });
    test('measure returns icon slot for PUA', () {
      final p = RecordingPainter(width: 300, height: 30);
      final w = BarText.measure(p, '\uE001');
      expect(w, BarMetrics.current.iconContentWidth());
    });
    test('measure returns text width for UI', () {
      final p = RecordingPainter(width: 300, height: 30);
      final w = BarText.measure(p, '12:34');
      expect(w, greaterThan(0));
    });
  });
}
