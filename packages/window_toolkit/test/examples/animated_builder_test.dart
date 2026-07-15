import 'dart:async' as async;
import 'package:test/test.dart';
import 'package:window_toolkit/window_toolkit.dart';

void main() {
  test('AnimatedBuilder rebuilds on animation tick', () async {
    final controller = AnimationController(duration: const Duration(milliseconds: 50));
    final builder = AnimatedBuilder(
      animation: controller,
      builder: (v) => Label('${v.round()}'),
    );

    int drawCount = 0;
    Widget.onNeedsRepaint = () { drawCount++; };

    final painter = RecordingPainter();
    controller.forward();

    // Manually advance the animation
    controller.tick(const Duration(milliseconds: 25));
    builder.x = 0;
    builder.y = 0;
    builder.width = 100;
    builder.height = 24;
    builder.draw(painter);

    // After tick, onNeedsRepaint should have been called
    expect(drawCount, greaterThanOrEqualTo(1));

    // Should have drawn something
    final texts = painter.commands.ofType<DrawTextCommand>().toList();
    expect(texts, hasLength(1));
    expect(texts[0].text, isNotNull);

    controller.dispose();
  });

  test('AnimatedBuilder builds with animation value', () {
    final controller = AnimationController(duration: const Duration(milliseconds: 100));

    // Test at t=0.5 with linear curve
    controller.forward();
    controller.tick(const Duration(milliseconds: 50));

    String? builtValue;
    final builder = AnimatedBuilder(
      animation: controller,
      builder: (v) {
        builtValue = '${v.toStringAsFixed(2)}';
        return SizedBox(width: 50, height: 20);
      },
    );

    final painter = RecordingPainter();
    builder.x = 10;
    builder.y = 10;
    builder.width = 100;
    builder.height = 24;
    builder.draw(painter);

    expect(builtValue, '0.50');
    controller.dispose();
  });

  test('AnimatedBuilder hitTest delegates to built widget', () {
    final controller = AnimationController(duration: const Duration(milliseconds: 100));
    controller.forward();
    controller.tick(const Duration(milliseconds: 50));

    final builder = AnimatedBuilder(
      animation: controller,
      builder: (v) => SizedBox(width: 100, height: 24),
    );

    builder.x = 0;
    builder.y = 0;
    builder.width = 100;
    builder.height = 24;

    expect(builder.hitTest(50, 12), isTrue);
    expect(builder.hitTest(200, 12), isFalse);
    controller.dispose();
  });
}
