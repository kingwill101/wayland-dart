import 'package:test/test.dart';
import 'package:window_toolkit/window_toolkit.dart';

void main() {
  setUp(() {
    FontDatabase.instance.useBitmapEngine();
    StyleContext.reset();
  });

  tearDown(StyleContext.reset);

  test('uses one style-resolved fallback-aware text run by default', () {
    final widget = TextRuns(
      '\u{f028} 55%',
      textFont: const Font.ui(pixelSize: 13),
      iconFont: const Font.icon(pixelSize: 14),
      color: const Color(255, 0, 0),
    );
    final painter = RecordingPainter(width: 320, height: 30);

    widget.measure(painter);
    widget
      ..x = 4
      ..y = 0
      ..height = 30;
    widget.draw(painter);

    expect(widget.width, greaterThan(0));
    final text = painter.commands.whereType<DrawTextCommand>().toList();
    expect(text, hasLength(1));
    expect(text[0].text, '\u{f028} 55%');
    expect(text.every((command) => command.color?.r == 255), isTrue);
  });

  test('supports explicit icon/UI splitting for callers that request it', () {
    final widget = TextRuns(
      '\u{f028} 55%',
      textFont: const Font.ui(pixelSize: 13),
      iconFont: const Font.icon(pixelSize: 14),
      splitPrivateUse: true,
    );
    final painter = RecordingPainter(width: 320, height: 30);

    widget.measure(painter);
    widget
      ..x = 4
      ..y = 0
      ..height = 30;
    widget.draw(painter);

    final text = painter.commands.whereType<DrawTextCommand>().toList();
    expect(text, hasLength(2));
    expect(text[0].text, '\u{f028}');
    expect(text[1].text, ' 55%');
  });

  test('uses CSS letter-spacing for icon/text run separation', () {
    final plain = TextRuns('󰖩 100%', splitPrivateUse: true);
    plain.measure(RecordingPainter(width: 320, height: 30));
    final plainWidth = plain.width;

    final css = CssProvider()..loadFromString('* { letter-spacing: 10px; }');
    StyleContext.addProvider(css, priority: StyleProviderPriority.user);
    final styled = TextRuns('󰖩 100%', splitPrivateUse: true);
    styled.measure(RecordingPainter(width: 320, height: 30));

    expect(styled.width, greaterThan(plainWidth));
  });

  test('split icon runs use the explicit icon font', () {
    final widget = TextRuns(
      '\u{f028} 55%',
      textFont: const Font(family: 'UI Face', pixelSize: 13),
      iconFont: const Font(family: 'Icon Face', pixelSize: 14),
      splitPrivateUse: true,
    );
    final painter = RecordingPainter(width: 320, height: 30);

    widget.measure(painter);
    widget
      ..x = 4
      ..y = 0
      ..height = 30;
    widget.draw(painter);

    final text = painter.commands.whereType<DrawTextCommand>().toList();
    expect(text, hasLength(2));
    expect(text[0].fontFamily, 'Icon Face');
    expect(text[1].fontFamily, 'UI Face');
  });

  test('takes the family stack and size from the widget style', () {
    final css = CssProvider()
      ..loadFromString(
        '* { font-family: "Icon Face", "Noto Color Emoji", sans-serif; '
        'font-size: 17px; }',
      );
    StyleContext.addProvider(css, priority: StyleProviderPriority.user);

    final widget = TextRuns('󰖩 100%');
    final painter = RecordingPainter(width: 320, height: 30);
    widget
      ..measure(painter)
      ..x = 4
      ..height = 30
      ..draw(painter);

    final command = painter.commands.whereType<DrawTextCommand>().single;
    expect(command.fontFamily, 'Icon Face, Noto Color Emoji, sans-serif');
    expect(command.size, 17);
  });

  test('updates intrinsic width when formatted output changes', () {
    final widget = TextRuns('55%');
    final painter = RecordingPainter(width: 320, height: 30);

    widget.measure(painter);
    final short = widget.width;
    widget.text = 'Volume 100%';
    widget.measure(painter);

    expect(widget.width, greaterThan(short));
  });

  test('centers mixed UI and icon runs using their combined ink bounds', () {
    final widget = TextRuns(
      '\u{f028} 55%',
      textFont: const Font(family: 'UI Face', pixelSize: 13),
      iconFont: const Font(family: 'Icon Face', pixelSize: 14),
      splitPrivateUse: true,
    );
    final painter = _MixedBoundsPainter(width: 320, height: 30);

    widget.measure(painter);
    widget
      ..x = 4
      ..y = 0
      ..height = 30;
    widget.draw(painter);

    final text = painter.commands.whereType<DrawTextCommand>().toList();
    expect(text, hasLength(2));
    // UI bounds are [2, 14], icon bounds are [-2, 12]. Each run is centered
    // independently in the 30px box, so both actual ink centers land at 15.
    expect(text[0].position.dy, closeTo(10, 0.001));
    expect(text[1].position.dy, closeTo(7, 0.001));
  });

  test('reserves icon ink overhang before drawing following text', () {
    final widget = TextRuns(
      '\u{f028} 100%',
      textFont: const Font(family: 'UI Face', pixelSize: 13),
      iconFont: const Font(family: 'Icon Face', pixelSize: 14),
      splitPrivateUse: true,
    );
    final painter = _MixedBoundsPainter(width: 320, height: 30);

    expect(
      painter.measureTextRunAdvance(
        '\u{f028}',
        const Font(family: 'Icon Face', pixelSize: 14),
      ),
      10,
    );

    widget
      ..measure(painter)
      ..x = 4
      ..height = 30
      ..draw(painter);

    final text = painter.commands.whereType<DrawTextCommand>().toList();
    expect(text, hasLength(2));
    expect(text[0].fontFamily, 'Icon Face');
    // The icon's ink reaches x=10 while its bitmap advance is smaller. The
    // following run must start after that ink plus the configured run gap.
    expect(text[1].position.dx, greaterThanOrEqualTo(17));
  });
}

class _MixedBoundsPainter extends RecordingPainter {
  _MixedBoundsPainter({super.width, super.height});

  @override
  Rect measureTextBounds(
    String text, {
    double size = 14,
    String fontFamily = 'sans',
  }) {
    if (fontFamily.contains('Icon')) {
      return const Rect.fromLTRB(0, -2, 10, 12);
    }
    return const Rect.fromLTRB(0, 2, 20, 14);
  }
}
