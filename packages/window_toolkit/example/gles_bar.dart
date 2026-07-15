/// GPU-accelerated bar using GlesPainter directly.
///
/// Creates a Wayland layer-surface window and explicitly overrides
/// [createPainter] to return [GlesPainter] — no Skia, no software
/// fallback. Every rectangle, line, and text glyph is drawn by the GPU.
///
/// Usage: run under a Wayland compositor (sway, Hyprland, river, …).
library;

import 'package:window_toolkit/window_toolkit.dart';

void main() async {
  final bar = GlesBar(
    anchor: Anchor.top,
    barHeight: 36,
  );
  bar.rendererBackend = RendererBackend.gl;
  await bar.show();
  Application.instance.exec();
}

/// A layer-surface window using GLES2 rendering.
class GlesBar extends LayerWindow {
  GlesBar({super.anchor, super.barHeight});

  // createPainter is handled by LayerBackend according to backend enum.
  // No override needed — RendererBackend.gl selects GlesPainter.

  @override
  void draw(Painter painter) {
    // Black background, white text.
    painter.clear(const Color(0, 0, 0));

    final rh = height * 0.6;
    final pads = 12.0;
    final cy = (height - rh) / 2;

    // Workspace chips.
    painter.drawRRect(
      Rect.fromLTWH(pads, cy, 40, rh), 4, 4,
      Paint()..color = const Color(0xff, 0xff, 0xff),
    );
    for (var i = 0; i < 4; i++) {
      painter.drawRRect(
        Rect.fromLTWH(pads + 44 + i * 34, cy, 30, rh), 3, 3,
        Paint()..color = const Color(0x40, 0x40, 0x40),
      );
    }

    // Clock text right-aligned.
    final now = DateTime.now();
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final tw = painter.measureText(timeStr, size: 14).width;
    painter.drawText(timeStr, Offset(width - pads - tw, (height - 14) / 2),
        color: const Color(0xff, 0xff, 0xff), size: 14);

    // Bottom accent line.
    painter.drawLine(
      Offset(0, height - 1.0), Offset(width.toDouble(), height - 1.0),
      Paint()..color = const Color(0xff, 0xff, 0xff)..strokeWidth = 1.0,
    );
  }
}
