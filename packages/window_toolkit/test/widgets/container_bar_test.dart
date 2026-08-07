import 'package:test/test.dart';
import 'package:window_toolkit/window_toolkit.dart';

/// Fixed-width module stand-in (bardash ModuleWidget).
class _Mod extends Widget {
  final int contentW;
  _Mod(this.contentW) {
    width = contentW;
    height = 14;
  }

  @override
  void measure(Painter p) {
    width = contentW;
    height = p.height.round() > 0 ? p.height.round() : 30;
  }

  @override
  void performLayout(int containerWidth) {
    // Must NOT expand to containerWidth (bar strip).
    height = 30;
  }

  @override
  void draw(Painter p) {}
}

void main() {
  group('Container bar layout', () {
    test('right modules keep measured widths and do not pile up', () {
      final container = Container(spacing: 4);
      final widths = [40, 50, 60, 30, 80];
      for (final w in widths) {
        container.right.add(_Mod(w));
      }

      final painter = RecordingPainter();
      for (final w in container.right) {
        w.measure(painter);
      }
      container
        ..x = 0
        ..y = 0
        ..width = 1920
        ..height = 30;
      container.layout(1920, 30);

      // Packed from the right: last module ends at bar width.
      final last = container.right.last;
      expect(last.x + last.width, 1920);

      // Spacing between neighbors preserved.
      for (var i = 0; i < container.right.length - 1; i++) {
        final a = container.right[i];
        final b = container.right[i + 1];
        expect(b.x, a.x + a.width + 4,
            reason: 'module $i and ${i + 1} must keep spacing');
        expect(a.width, widths[i]);
      }
    });

    test('module widths do not expand after layout+draw cycle', () {
      final container = Container(spacing: 6);
      final a = _Mod(48);
      final b = _Mod(64);
      container.right.addAll([a, b]);

      final painter = RecordingPainter();
      container
        ..width = 800
        ..height = 30;
      for (final w in container.right) {
        w.measure(painter);
      }
      container.layout(800, 30);
      for (final w in container.right) {
        w.draw(painter);
      }

      expect(a.width, 48);
      expect(b.width, 64);
      expect(b.x, greaterThan(a.x + a.width));
    });
  });
}
