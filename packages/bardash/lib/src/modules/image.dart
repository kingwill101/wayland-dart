import 'dart:io';

import 'package:window_toolkit/window_toolkit.dart';

import '../metrics.dart';
import 'module.dart';

/// Image display module.
///
/// Loads and renders a PNG/JPEG image file directly in the bar using the
/// Painter's `drawImage` method (backed by Skia image decoding).
///
/// Format placeholders:
///   (none — the image is drawn directly, no text output)
///
/// Config keys:
///   path        – path to image file (required)
///   size        – icon size in pixels (default: 16, square)
///   interval    – refresh in seconds (default: 0 = never)
///   on-click    – command on click
class ImageModule extends BarModule {
  @override
  String get name => 'image';

  @override
  bool get showsGraphics => true;

  String _path = '';
  int _size = 16;

  @override
  void init(Map<String, String> config) {
    super.init(config);
    format = resolveFormat(config, '', '');
    interval = parseInt(config, 'interval', 0);
    _size = parseInt(config, 'size', 16);
    _path = config['path'] ?? '';
  }

  @override
  void update() {
    if (_path.isEmpty || !File(_path).existsSync()) {
      output = '?img';
      return;
    }
    output = '';
  }

  @override
  double measure(Painter painter) {
    return _size.toDouble();
  }

  @override
  double draw(Painter painter, double x, double y) {
    final glyph = BarMetrics.current.fontSize.round();
    final yOffset = y + (_size < glyph ? (glyph - _size) / 2 : 0);
    if (_path.isEmpty || !File(_path).existsSync()) {
      // Draw placeholder square (CSS foreground for consistency)
      painter.drawRect(
        Rect.fromLTWH(x, yOffset, _size.toDouble(), _size.toDouble()),
        Paint()..color = cssColor(const Color(0x3a, 0x3a, 0x3a)),
      );
      return _size.toDouble();
    }

    // Center the image vertically within the bar height
    painter.drawImage(
      _path,
      x,
      yOffset,
      width: _size.toDouble(),
      height: _size.toDouble(),
    );
    return _size.toDouble();
  }
}
