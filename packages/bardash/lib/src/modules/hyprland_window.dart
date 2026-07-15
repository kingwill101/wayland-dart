import 'package:window_toolkit/window_toolkit.dart';

import '../native/hyprland_ipc.dart' as ipc;
import 'module.dart';

/// Hyprland focused window title via direct IPC.
///
/// Truncates long titles with an ellipsis (configurable via `max-width`).
class HyprlandWindowModule extends BarModule {
  @override
  String get name => 'hyprland/window';

  String _title = '';
  int _maxWidth = 200; // pixels

  @override
  void init(Map<String, String> config) {
    super.init(config);
    format = resolveFormat(config, '{title}', '');
    interval = 1;
    _maxWidth = parseInt(config, 'max-width', 200);
  }

  @override
  void update() {
    final data = ipc.hyprctl('activewindow');
    if (data is! Map || data['mapped'] != true) { widget = null; output = ''; return; }

    _title = data['title']?.toString() ?? '';
    final cls = data['class']?.toString() ?? '';

    output = format
        .replaceAll('{title}', _title)
        .replaceAll('{class}', cls);

    widget = _buildLabel();
  }

  Widget _buildLabel() => _TruncatedLabel(_title, _maxWidth);

  @override
  double draw(Painter painter, double x, double y) => 0;
}

/// A Label that truncates with ellipsis when wider than [maxWidth] pixels.
class _TruncatedLabel extends Widget {
  final String text;
  final int maxWidth;

  _TruncatedLabel(this.text, this.maxWidth) {
    // Do not reserve [maxWidth] up front — empty titles used to leave a huge
    // hole on the left of the bar. Width is set in [measure].
    width = 0;
    height = 16;
  }

  @override
  void measure(Painter painter) {
    if (text.isEmpty) {
      width = 0;
      height = 16;
      return;
    }
    final full = painter.measureText(text, size: 14).width.round();
    width = full.clamp(0, maxWidth);
    height = 16;
  }

  @override
  void draw(Painter painter) {
    if (text.isEmpty) return;
    final full = painter.measureText(text, size: 14).width;
    final elide = full > maxWidth;
    final display = elide ? _elideText(painter) : text;
    painter.drawText(display, Offset(x.toDouble(), y.toDouble()), size: 14);
  }

  @override
  bool hitTest(int px, int py) {
    if (width <= 0) return false;
    return px >= x && px < x + width && py >= y && py < y + height;
  }

  String _elideText(Painter painter) {
    // Binary search for the longest prefix that fits
    const ellipsis = '\u2026';
    final ellipsisW = painter.measureText(ellipsis, size: 14).width;
    final targetW = maxWidth - ellipsisW.round();
    if (targetW <= 0) return ellipsis;

    int lo = 0, hi = text.length;
    while (lo < hi) {
      final mid = (lo + hi + 1) ~/ 2;
      final w = painter.measureText(text.substring(0, mid), size: 14).width;
      if (w <= targetW) {
        lo = mid;
      } else {
        hi = mid - 1;
      }
    }
    return '${text.substring(0, lo)}$ellipsis';
  }
}
