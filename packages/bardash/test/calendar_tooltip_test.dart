import 'package:window_toolkit/window_toolkit.dart';
import 'package:test/test.dart';

import '../lib/src/calendar_tooltip.dart';

void main() {
  group('calendar_tooltip', () {
    test('renders multi-row grid with distinct baselines (no single-line collapse)', () {
      final root = buildCalendarTooltip(DateTime(2025, 3, 15), fontSize: 12);
      root.performLayout(300);
      final rec = RecordingPainter();
      root.draw(rec);

      // at least title + weekday + 5 day rows on distinct baselines
      final bases = <double>{};
      for (final c in rec.commands) {
        if (c is DrawTextCommand) bases.add(c.position.dy.roundToDouble());
      }
      expect(bases.length, greaterThanOrEqualTo(7));
    });

    test('day numbers are horizontally centered in their column', () {
      final root = buildCalendarTooltip(DateTime(2025, 3, 15), fontSize: 12);
      root.performLayout(300);
      final rec = RecordingPainter();
      root.draw(rec);

      // For each day text, its baseline x must sit inside its column and
      // closer to the column's center than its left edge.
      final texts = <DrawTextCommand>[
        for (final c in rec.commands)
          if (c is DrawTextCommand && RegExp(r'^\d{1,2}$').hasMatch(c.text)) c,
      ];
      expect(texts.length, greaterThanOrEqualTo(29)); // all 1..31 (some blank)

      for (final t in texts) {
        final colLeft = (t.position.dx / 40).floor() * 40.0;
        final center = colLeft + 20;
        // centered → within 15px of column center (40/2)
        expect(
          (t.position.dx - center).abs(),
          lessThanOrEqualTo(15.0),
          reason: '"${t.text}" should be centered in its column (x=${t.position.dx})',
        );
      }
    });

    test('today number is centered inside its highlight pill', () {
      final root = buildCalendarTooltip(DateTime(2025, 3, 15), fontSize: 12);
      root.performLayout(300);
      final rec = RecordingPainter();
      root.draw(rec);

      // the single filled pill (today highlight)
      final pill = rec.commands.whereType<DrawRectCommand>().where(
            (c) => c.paint.style == PaintStyle.fill,
          );
      final pills = pill.toList();
      expect(pills.length, 1, reason: 'exactly one today highlight pill');
      final r = pills.first.rect;

      final todayText = rec.commands
          .whereType<DrawTextCommand>()
          .firstWhere((c) => c.text == '15');
      // baseline sits inside the pill horizontally, near horizontal center
      expect(todayText.position.dx, greaterThan(r.left + 2));
      expect(todayText.position.dx, lessThan(r.left + r.width - 2));
      expect(
        (todayText.position.dx - (r.left + r.width / 2)).abs(),
        lessThan(12.0),
        reason: 'today number should be centered in its pill',
      );
    });
  });
}