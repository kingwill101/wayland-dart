import 'package:window_toolkit/window_toolkit.dart';

// Shared weekday / month names for the calendar tooltip widget.
const _weekdaysShort = ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'];
const _monthsFull = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

/// A single calendar grid cell (weekday label, day number, or the padded
/// gap). Fills its cell and draws its text **centered** both ways; when
/// [background] is set it paints a rounded highlight pill of exactly that
/// cell, with the number centered in it.
class _CalendarCell extends Widget {
  final String text;
  final Color textColor;
  final double fontSize;
  final Color? background;
  final double radius;
  final int? fixedWidth;
  final int? fixedHeight;

  _CalendarCell({
    required this.text,
    required this.textColor,
    required this.fontSize,
    required this.background,
    required this.radius,
    int? width,
    int? height,
  })  : fixedWidth = width,
        fixedHeight = height {
    if (width != null) this.width = width;
    if (height != null) this.height = height;
  }

  @override
  void measure(Painter painter) {
    // Fixed cells report their own size; fill cells are sized by the parent.
    if (fixedWidth != null) width = fixedWidth!;
    if (fixedHeight != null) height = fixedHeight!;
  }

  @override
  void performLayout(int containerWidth) {
    width = fixedWidth ?? containerWidth;
    height = fixedHeight ?? height;
  }

  @override
  void draw(Painter canvas) {
    final rect = Rect.fromLTWH(
      x.toDouble(),
      y.toDouble(),
      width.toDouble(),
      height.toDouble(),
    );
    final bg = background;
    if (bg != null) {
      if (radius > 0) {
        canvas.drawRRect(rect, radius, radius, Paint()..color = bg);
      } else {
        canvas.drawRect(rect, Paint()..color = bg);
      }
    }
    if (text.isEmpty) return;
    canvas.drawTextInRect(
      text,
      rect,
      font: Font(family: 'sans', pixelSize: fontSize),
      option: TextOption(align: TextAlign.center),
      color: textColor,
    );
  }
}

/// Builds the calendar tooltip as a real [Widget], laid out and painted
/// through the toolkit's widget + style system (no ad-hoc painter code).
///
/// Every calendar cell is a [_CalendarCell]: a fixed-size leaf that fills its
/// column and centers the number in its rect ([TextAlign.center]). The
/// "today" cell paints a rounded highlight of the cell size *behind* the
/// number, so the digit is centered in the background color.
///
/// Colors come from the [Palette] (the style system's palette source) so the
/// grid stays cohesive with the rest of the theme. The widget also carries
/// CSS classes (`calendar`, `weekday`, `today`) for future theming through a
/// CSS provider wired via `StyleContext` ancestry.
Widget buildCalendarTooltip(DateTime now, {double fontSize = 12, double radius = 8}) {
  final palette = (Palette.current).forState(true, true);

  final textColor = palette.tooltipText;
  final weekdayColor = Color(textColor.r, textColor.g, textColor.b, 140);
  final todayBg = palette.highlight;
  final todayFg = palette.highlightedText;

  final cellW = (fontSize * 3.3).round().clamp(36, 72);
  final cellH = (fontSize * 2.6).round().clamp(18, 24);

  final week = 'weekday';
  final day = 'day';

  Widget cell(String s,
      {required Color color, bool today = false, bool weekday = false}) {
    final c = _CalendarCell(
      text: s,
      textColor: today ? todayFg : color,
      fontSize: fontSize,
      background: today ? todayBg : null,
      radius: radius,
      width: cellW,
      height: cellH,
    )..addClass(weekday ? week : day);
    if (today) c.addClass('today');
    return c;
  }

  Widget row(List<String> labels, {required bool weekdayRow}) {
    return HBox(
      children: [
        for (final d in labels)
          cell(
            d,
            color: weekdayRow ? weekdayColor : textColor,
            today: !weekdayRow && d == now.day.toString(),
            weekday: weekdayRow,
          ),
      ],
    )..addClass(weekdayRow ? 'weekdays' : 'days');
  }

  final year = now.year;
  final month = now.month;
  final first = DateTime(year, month, 1);
  final daysInMonth = DateTime(year, month + 1, 0).day;
  final startPad = first.weekday % 7; // Sunday-first

  // Build day matrix as 7 columns: leading blanks, then 1..daysInMonth.
  final rows = <List<String>>[];
  var cells = <String>[];
  for (var i = 0; i < startPad; i++) {
    cells.add('');
  }
  for (var day = 1; day <= daysInMonth; day++) {
    cells.add('$day');
    if (cells.length == 7) {
      rows.add(cells);
      cells = <String>[];
    }
  }
  if (cells.isNotEmpty) rows.add(cells);

  final root = VBox(spacing: (fontSize * 0.7).round());
  // The root carries the `calendar` style class for CSS theming.
  root.addClass('calendar');

  // Centered title spans the whole grid width.
  root.children.add(
    _CalendarCell(
      text: '${_monthsFull[month - 1]} $year',
      textColor: textColor,
      fontSize: fontSize + 4,
      background: null,
      radius: 0,
      height: (fontSize * 2).round(),
    ),
  );
  root.children.add(row(_weekdaysShort, weekdayRow: true));
  for (final r in rows) {
    root.children.add(row(r, weekdayRow: false));
  }

  return root;
}