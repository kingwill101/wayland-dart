/// Reactive, responsive window_toolkit demo.
library;

import 'dart:async' as async;
import 'dart:math';

import 'package:window_toolkit/window_toolkit.dart';

void main() async {
  final demo = DemoWindow();
  demo.rendererBackend = RendererBackend.gl;
  await demo.show();
  Application.instance.exec();
}

class DemoWindow extends WidgetWindow {
  int _clicks = 0;
  String _clock = '--:--:--';
  async.Timer? _timer;

  late final Label _clockLbl;
  late final Label _clickLbl;

  DemoWindow() : super(VBox(spacing: 12, children: [])) {
    _clockLbl = Label('--:--:--', fontSize: 48, color: const Color(0xee, 0xee, 0xee));
    _clickLbl = Label('Clicks: 0', fontSize: 14, color: const Color(0xaa, 0xaa, 0xaa));

    root = VBox(spacing: 12, children: [
      // Header
      HBox(spacing: 8, children: [
        Label('window_toolkit', fontSize: 22, color: const Color(0xff, 0xff, 0xff)),
        Spacer(),
        Label('GLES2', fontSize: 11, color: const Color(0x66, 0x88, 0x66)),
      ]),

      // Canvas with stroke / fill / gradient demos
      _DemoCanvas(400, 80),

      // Buttons
      HBox(spacing: 8, children: [
        Button('Click me', onPressed: () {
          _clicks++;
          _clickLbl.text = 'Clicks: $_clicks';
          paint();
        }),
        Button('Reset', onPressed: () {
          _clicks = 0;
          _clickLbl.text = 'Clicks: 0';
          paint();
        }),
        Spacer(),
      ]),

      _clickLbl,

      Spacer(),
      Align(
        child: Label('Resize the window → responsive layout',
            fontSize: 11, color: const Color(0x66, 0x66, 0x66)),
        horizontalAlignment: HorizontalAlignment.center,
      ),
    ]);

    _timer = async.Timer.periodic(const Duration(seconds: 1), (_) {
      final now = DateTime.now();
      _clock = '${_pad(now.hour)}:${_pad(now.minute)}:${_pad(now.second)}';
      _clockLbl.text = _clock;
      paint();
    });
  }

  static String _pad(int n) => n.toString().padLeft(2, '0');

  @override
  void draw(Painter painter) {
    painter.drawLinearGradient(
      Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
      const Color(0x0a, 0x0c, 0x12),
      const Color(0x18, 0x1c, 0x24),
      angle: pi / 2,
    );
    super.draw(painter);

    _clockLbl.x = 16;
    _clockLbl.y = height - 80;
    _clockLbl.width = width - 32;
    _clockLbl.draw(painter);
  }
}

class _DemoCanvas extends Widget {
  @override final int width, height;
  _DemoCanvas(this.width, this.height);

  @override
  void draw(Painter painter) {
    final x = this.x.toDouble();
    final y = this.y.toDouble();
    final w = width.toDouble();
    final h = height.toDouble();

    painter.drawRRect(Rect.fromLTWH(x + 4, y + 4, w / 3 - 8, h - 8),
        6, 6, Paint()..color = const Color(0x40, 0x60, 0x90));
    painter.drawCircle(Offset(x + w * 0.6, y + h * 0.35), h * 0.3,
        Paint()..color = const Color(0x80, 0xa0, 0xc0)
          ..style = PaintStyle.stroke..strokeWidth = 2);
    painter.drawCircle(Offset(x + w * 0.6, y + h * 0.75), 6,
        Paint()..color = const Color(0xa0, 0xc0, 0x60));
    painter.drawLinearGradient(
        Rect.fromLTWH(x + w * 0.78, y + 4, w * 0.18, h - 8),
        const Color(0x60, 0x40, 0x80),
        const Color(0x80, 0x60, 0xa0), angle: 0.0);
    painter.drawRect(Rect.fromLTWH(x + w * 0.78, y + h * 0.55, w * 0.18, h * 0.35),
        Paint()..color = const Color(0xc0, 0x80, 0x40)
          ..style = PaintStyle.stroke..strokeWidth = 1.5);
    painter.drawLine(Offset(x + w / 3 + 4, y + h - 4),
        Offset(x + w * 0.6 - 4, y + h * 0.55),
        Paint()..color = const Color(0x80, 0x80, 0x80)..strokeWidth = 1);
  }
}
