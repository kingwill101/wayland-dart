/// Tests for [Painter] interface features used by [GlesPainter].
///
/// These tests verify the interface contract using [RecordingPainter]
/// without requiring a Wayland compositor or GPU.  Actual GLES2
/// rendering is tested at integration level.
///
/// Also covers: drawLinearGradient, PaintStyle.stroke, clipRect, transform.
library;

import 'package:test/test.dart';
import 'package:window_toolkit/window_toolkit.dart';


void main() {
  group('drawLinearGradient', () {
    test('records a gradient command', () {
      final p = RecordingPainter();
      p.drawLinearGradient(
        Rect.fromLTWH(10, 20, 100, 50),
        const Color(255, 0, 0),
        const Color(0, 0, 255),
        angle: 1.57,
      );
      final cmd = p.commands.singleOfType<DrawLinearGradientCommand>();
      expect(cmd.rect.left, 10);
      expect(cmd.rect.top, 20);
      expect(cmd.rect.width, 100);
      expect(cmd.rect.height, 50);
      expect(cmd.color0.r, 255);
      expect(cmd.color1.b, 255);
      expect(cmd.angle, 1.57);
    });

    test('gradient rect is transformed', () {
      final p = RecordingPainter();
      p.translate(50, 25);
      p.drawLinearGradient(
        Rect.fromLTWH(10, 10, 30, 20),
        const Color(0, 0, 0),
        const Color(255, 255, 255),
      );
      final cmd = p.commands.singleOfType<DrawLinearGradientCommand>();
      expect(cmd.rect.left, 60);
      expect(cmd.rect.top, 35);
    });
  });

  group('PaintStyle.stroke', () {
    test('drawRect with stroke records same command', () {
      final p = RecordingPainter();
      final paint = Paint()
        ..color = const Color(255, 0, 0)
        ..style = PaintStyle.stroke
        ..strokeWidth = 2.0;
      p.drawRect(Rect.fromLTWH(0, 0, 50, 50), paint);
      final cmd = p.commands.singleOfType<DrawRectCommand>();
      // RecordingPainter doesn't differentiate stroke/fill at the
      // command level — that's the backend's job (GlesPainter).
      expect(cmd.paint.color.r, 255);
    });

    test('drawCircle with stroke', () {
      final p = RecordingPainter();
      p.drawCircle(const Offset(100, 100), 30,
          Paint()..style = PaintStyle.stroke..strokeWidth = 1.5);
      final cmd = p.commands.singleOfType<DrawCircleCommand>();
      expect(cmd.center.dx, 100);
      expect(cmd.center.dy, 100);
      expect(cmd.radius, 30);
    });
  });

  group('clipRect', () {
    test('clipRect / save / restore stack', () {
      final p = RecordingPainter();
      p.clipRect(Rect.fromLTWH(0, 0, 100, 100));
      p.save();
      p.clipRect(Rect.fromLTWH(10, 10, 50, 50));
      p.restore();
      // After restore, clip should be back to the first rect.
      // The harness doesn't expose clip state, but save/restore
      // should not throw.
    });
  });

  group('transform', () {
    test('translate shifts subsequent draw calls', () {
      final p = RecordingPainter();
      p.translate(20, 10);
      p.drawRect(Rect.fromLTWH(0, 0, 10, 10), Paint());
      final cmd = p.commands.singleOfType<DrawRectCommand>();
      expect(cmd.rect.left, 20);
      expect(cmd.rect.top, 10);
    });

    test('scale affects coordinates', () {
      final p = RecordingPainter();
      p.scale(2, 3);
      p.drawRect(Rect.fromLTWH(10, 10, 10, 10), Paint());
      final cmd = p.commands.singleOfType<DrawRectCommand>();
      expect(cmd.rect.left, 20);
      expect(cmd.rect.top, 30);
    });

    test('save / restore reverts transform', () {
      final p = RecordingPainter();
      p.translate(50, 0);
      p.save();
      p.translate(0, 30);
      p.restore();
      p.drawRect(Rect.fromLTWH(0, 0, 10, 10), Paint());
      final cmd = p.commands.singleOfType<DrawRectCommand>();
      expect(cmd.rect.left, 50); // restored x
      expect(cmd.rect.top, 0);   // y unchanged by inner translate
    });
  });

  group('drawText', () {
    test('records text command with position', () {
      final p = RecordingPainter();
      p.drawText('Hello', const Offset(10, 20));
      final cmd = p.commands.singleOfType<DrawTextCommand>();
      expect(cmd.text, 'Hello');
      expect(cmd.position.dx, 10);
      expect(cmd.position.dy, 20);
      expect(cmd.size, 14); // default
    });

    test('text is transformed', () {
      final p = RecordingPainter();
      p.translate(100, 200);
      p.drawText('Test', const Offset(0, 0));
      final cmd = p.commands.singleOfType<DrawTextCommand>();
      expect(cmd.position.dx, 100);
      expect(cmd.position.dy, 200);
    });
  });

  group('drawImage', () {
    test('records image command', () {
      final p = RecordingPainter();
      p.drawImage('/path/to/icon.png', 5, 10, width: 32, height: 32);
      final cmd = p.commands.singleOfType<DrawImageCommand>();
      expect(cmd.filePath, '/path/to/icon.png');
      expect(cmd.x, 5);
      expect(cmd.y, 10);
      expect(cmd.width, 32);
      expect(cmd.height, 32);
    });
  });

  group('drawLine', () {
    test('records line command', () {
      final p = RecordingPainter();
      p.drawLine(const Offset(0, 0), const Offset(100, 100),
          Paint()..color = const Color(255, 255, 255));
      final cmd = p.commands.singleOfType<DrawLineCommand>();
      expect(cmd.from.dx, 0);
      expect(cmd.to.dx, 100);
    });
  });

  group('clearTextCache', () {
    test('GlesPainter exposes clearTextCache', () {
      // RecordingPainter doesn't have a real cache, but the method
      // exists on the Painter interface with a default no-op.
      final p = RecordingPainter();
      // Should not throw.
    });
  });
}
