import 'package:window_toolkit/window_toolkit.dart';

import '../calendar_tooltip.dart';
import '../metrics.dart';
import 'module.dart';

const _weekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
const _weekdaysShort = ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'];
const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];
const _monthsFull = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

class ClockModule extends BarModule {
  @override
  String get name => 'clock';

  /// The clock tooltip is a calendar; render it as a widget through the
  /// toolkit's widget + style system.
  @override
  Widget? get tooltipContent => buildCalendarTooltip(DateTime.now(), fontSize: 12);

  Color _color = const Color(0xc8, 0xc8, 0xc8);
  bool _calendarInTooltip = true;

  @override
  void init(Map<String, String> config) {
    super.init(config);
    format = resolveFormat(config, '%H:%M', '');
    interval = 1;
    if (config.containsKey('color')) {
      _color = parseColor(config['color']!);
    }
    _calendarInTooltip = config['calendar'] != 'false';
  }

  @override
  void update() {
    final n = DateTime.now();
    output = _formatTime(n, format);

    if (tooltipFormat.isNotEmpty) {
      var tip = tooltipFormat.replaceAll('{calendar}', _buildCalendar(n));
      tip = _expandDateTokens(tip, n);
      tooltip = tip;
    } else if (_calendarInTooltip) {
      final header = '${_weekdays[n.weekday % 7]} ${n.day} '
          '${_monthsFull[n.month - 1]} ${n.year}\n'
          '${n.hour.toString().padLeft(2, '0')}:'
          '${n.minute.toString().padLeft(2, '0')}:'
          '${n.second.toString().padLeft(2, '0')}';
      tooltip = '$header\n\n${_buildCalendar(n)}';
    } else {
      tooltip =
          '${n.hour.toString().padLeft(2, '0')}:'
          '${n.minute.toString().padLeft(2, '0')}:'
          '${n.second.toString().padLeft(2, '0')}';
    }
  }

  String _expandDateTokens(String tip, DateTime n) {
    return tip
        .replaceAll('%Y', n.year.toString().padLeft(4, '0'))
        .replaceAll('%m', n.month.toString().padLeft(2, '0'))
        .replaceAll('%d', n.day.toString().padLeft(2, '0'))
        .replaceAll('%H', n.hour.toString().padLeft(2, '0'))
        .replaceAll('%M', n.minute.toString().padLeft(2, '0'))
        .replaceAll('%S', n.second.toString().padLeft(2, '0'))
        .replaceAll('%B', _monthsFull[n.month - 1])
        .replaceAll('%b', _months[n.month - 1])
        .replaceAll('%A', _weekdays[n.weekday % 7])
        .replaceAll('%a', _weekdaysShort[n.weekday % 7]);
  }

  /// Plain-text month grid. Today marked with trailing `*`.
  String _buildCalendar(DateTime now) {
    final year = now.year;
    final month = now.month;
    final first = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final startPad = first.weekday % 7; // Sunday-first

    final out = StringBuffer();
    final title = '${_monthsFull[month - 1]} $year';
    final pad = ((21 - title.length) ~/ 2).clamp(0, 21);
    out.writeln('${' ' * pad}$title');
    out.writeln(_weekdaysShort.join(' '));

    var col = 0;
    for (var i = 0; i < startPad; i++) {
      out.write('   ');
      col++;
    }
    for (var day = 1; day <= daysInMonth; day++) {
      final body = day.toString().padLeft(2);
      out.write(day == now.day ? '$body*' : '$body ');
      col++;
      if (col == 7) {
        out.writeln();
        col = 0;
      }
    }
    if (col != 0) out.writeln();
    return out.toString().trimRight();
  }

  @override
  double measure(Painter painter) {
    final font = Font.ui(pixelSize: BarMetrics.current.fontSize);
    return painter.measureTextFont(output, font);
  }

  @override
  double draw(Painter painter, double x, double y) {
    final font = Font.ui(pixelSize: BarMetrics.current.fontSize);
    painter.drawTextFont(output, Offset(x, y), font: font, color: _color);
    return painter.measureTextFont(output, font);
  }

  String _formatTime(DateTime dt, String fmt) {
    final buffer = StringBuffer();
    var i = 0;
    while (i < fmt.length) {
      if (fmt[i] == '%' && i + 1 < fmt.length) {
        i++;
        switch (fmt[i]) {
          case 'H':
            buffer.write(dt.hour.toString().padLeft(2, '0'));
          case 'M':
            buffer.write(dt.minute.toString().padLeft(2, '0'));
          case 'S':
            buffer.write(dt.second.toString().padLeft(2, '0'));
          case 'Y':
            buffer.write(dt.year.toString().padLeft(4, '0'));
          case 'm':
            buffer.write(dt.month.toString().padLeft(2, '0'));
          case 'd':
            buffer.write(dt.day.toString().padLeft(2, '0'));
          case 'a':
            buffer.write(_weekdays[dt.weekday % 7]);
          case 'b':
            buffer.write(_months[dt.month - 1]);
          case 'B':
            buffer.write(_monthsFull[dt.month - 1]);
          case 'A':
            buffer.write(_weekdays[dt.weekday % 7]);
          default:
            buffer.write('%${fmt[i]}');
        }
      } else {
        buffer.write(fmt[i]);
      }
      i++;
    }
    return buffer.toString();
  }
}
