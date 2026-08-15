import 'package:test/test.dart';
import 'package:window_toolkit/window_toolkit.dart';

void main() {
  test('FontTextRun splits private-use icons from UI text', () {
    final runs = FontTextRun.split(
      '\u{f028} 90%',
      textFont: const Font.ui(pixelSize: 13),
      iconFont: const Font.icon(pixelSize: 14),
    );

    expect(runs, hasLength(2));
    expect(runs[0].text, '\u{f028}');
    expect(runs[0].font.role, FontRole.icon);
    expect(runs[1].text, ' 90%');
    expect(runs[1].font.role, FontRole.ui);
  });

  test('FontTextRun recognises supplementary private-use glyphs', () {
    expect(FontTextRun.isPrivateUse('\u{f0001}'), isTrue);
    expect(FontTextRun.isPrivateUse('90%'), isFalse);
  });
}
