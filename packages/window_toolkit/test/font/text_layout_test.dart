import 'package:test/test.dart';
import 'package:window_toolkit/window_toolkit.dart';

void main() {
  setUp(() {
    FontDatabase.instance.useBitmapEngine();
    FontDatabase.instance.setRoleFamily(FontRole.ui, 'bitmap');
    FontDatabase.instance.defaultPixelSize = 16;
  });

  test('baselineInBox centers ascent/descent in bar height', () {
    // ascent 8, descent 2 → line 10; bar 30
    // baseline = 0 + (30 + 8 - 2) / 2 = 18
    final b = TextLayout.baselineInBox(0, 30, ascent: 8, descent: 2);
    expect(b, closeTo(18, 0.01));
  });

  test('layoutInRect leftCenter places x at left and mid baseline', () {
    final font = Font.ui(pixelSize: 16);
    final rect = const Rect.fromLTWH(10, 0, 100, 30);
    final layout = TextLayout.layoutInRect(
      'AB', // 2 * 8 = 16 advance on bitmap
      rect,
      font: font,
      option: TextOption.leftCenter,
    );
    expect(layout.displayText, 'AB');
    expect(layout.advance, 16);
    expect(layout.baseline.dx, 10);
    // Glyph-bounds center minus optical lift (not full em-box).
    final m = FontDatabase.instance.metrics(font);
    final bounds = m.boundingRect('AB');
    final expectedY = TextLayout.baselineForVAlignWithBounds(
      0,
      30,
      TextVAlign.center,
      bounds,
    );
    expect(layout.baseline.dy, closeTo(expectedY, 0.5));
    // Must not sit in the lower third of a 30px bar.
    expect(layout.baseline.dy, lessThan(20));
  });

  test('layoutInRect h-center centers advance in width', () {
    final font = Font.ui(pixelSize: 16);
    final rect = const Rect.fromLTWH(0, 0, 100, 20);
    final layout = TextLayout.layoutInRect(
      'AB',
      rect,
      font: font,
      option: const TextOption(align: TextAlign.center),
    );
    // (100 - 16) / 2 = 42
    expect(layout.baseline.dx, closeTo(42, 0.5));
  });

  test('elide right shortens long text', () {
    final m = FontDatabase.instance.metrics(Font.ui(pixelSize: 16));
    // 20 cells * 8 = 160px; max 40px → short
    final elided = TextLayout.elide(
      'ABCDEFGHIJ',
      40,
      m,
      mode: TextElideMode.right,
    );
    expect(elided.endsWith('…'), isTrue);
    expect(m.horizontalAdvance(elided), lessThanOrEqualTo(40));
  });

  test('TextAlign equality', () {
    expect(TextAlign.center, TextAlign.center);
    expect(TextAlign.leftCenter.horizontal, TextHAlign.left);
    expect(TextAlign.leftCenter.vertical, TextVAlign.center);
  });
}
