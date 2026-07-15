import 'dart:io';

import 'package:window_toolkit/window_toolkit.dart';

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
    if (_path.isEmpty || !File(_path).existsSync()) {
      // Draw placeholder rectangle
      painter.drawRect(
        Rect.fromLTWH(x, y, _size.toDouble(), _size.toDouble()),
        Paint()..color = const Color(0x60, 0x40, 0x40),
      );
      return _size.toDouble();
    }

    // Center the image vertically within the bar height
    final yOffset = y + (_size < 14 ? (14 - _size) / 2 : 0);
    painter.drawImage(_path, x, yOffset, width: _size.toDouble(), height: _size.toDouble());
    return _size.toDouble();
  }
}
