import 'package:window_toolkit/window_toolkit.dart';

class UnicodeSampleRow extends Widget {
  final String label;
  final String sample;
  final Color labelColor;
  final Color sampleColor;

  UnicodeSampleRow(
    this.label,
    this.sample, {
    this.labelColor = const Color(180, 180, 180),
    this.sampleColor = const Color(255, 255, 255),
  }) {
    height = 30;
  }

  @override
  void draw(Painter painter) {
    final baseline = y.toDouble() + 20;
    painter.drawText(
      '$label:',
      Offset(x.toDouble(), baseline),
      color: labelColor,
      size: 14,
    );
    painter.drawText(
      sample,
      Offset((x + 140).toDouble(), baseline),
      color: sampleColor,
      size: 16,
    );
  }
}

Widget buildUnicodeExample() {
  final card = Card(
    title: 'Unicode rendering',
    children: [
      UnicodeSampleRow('Latin', 'café naïve coöperate'),
      UnicodeSampleRow('Symbols', '⚡ ○ ◑ ◕ ●'),
      UnicodeSampleRow('Battery', '🔋 🪫'),
      UnicodeSampleRow('Emoji', '😀 🚀 ✨'),
      UnicodeSampleRow('CJK', 'こんにちは世界'),
      UnicodeSampleRow('Cyrillic', 'Привет мир'),
      UnicodeSampleRow('Arabic', 'مرحبا بالعالم'),
    ],
  );

  card.width = 560;
  card.height = 290;

  return Padding(all: 24, child: card);
}
