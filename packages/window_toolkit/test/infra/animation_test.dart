import 'package:test/test.dart';
import 'package:window_toolkit/window_toolkit.dart';

void main() {
  group('Animation', () {
    test('AnimationController starts at 0.0', () {
      final c = AnimationController(duration: const Duration(milliseconds: 100));
      expect(c.value, closeTo(0.0, 1e-6));
      expect(c.status, AnimationStatus.dismissed);
    });

    test('AnimationController forward drives value to 1.0', () {
      final c = AnimationController(duration: const Duration(milliseconds: 100));
      double lastValue = 0.0;
      c.addListener(() {
        lastValue = c.value;
      });

      c.forward();
      // Advance halfway
      c.tick(const Duration(milliseconds: 50));
      expect(lastValue, closeTo(0.5, 0.05));
      expect(c.status, AnimationStatus.forward);

      // Complete
      c.tick(const Duration(milliseconds: 100));
      expect(lastValue, closeTo(1.0, 0.01));
      expect(c.status, AnimationStatus.completed);
      c.dispose();
    });

    test('AnimationController reverse drives value to 0.0', () {
      final c = AnimationController(duration: const Duration(milliseconds: 100));
      double lastValue = 0.0;
      c.addListener(() {
        lastValue = c.value;
      });

      // Go to 1.0
      c.forward();
      c.tick(const Duration(milliseconds: 100));
      expect(lastValue, closeTo(1.0, 0.01));

      // Reverse to 0.0
      c.reverse();
      c.tick(const Duration(milliseconds: 100));
      expect(lastValue, closeTo(0.0, 0.01));
      expect(c.status, AnimationStatus.completed);
      c.dispose();
    });

    test('AnimationController stop halts animation', () {
      final c = AnimationController(duration: const Duration(milliseconds: 200));
      double lastValue = 0.0;
      c.addListener(() {
        lastValue = c.value;
      });

      c.forward();
      c.tick(const Duration(milliseconds: 30));
      c.stop();

      final stoppedValue = lastValue;
      // Further ticks should not change value
      c.tick(const Duration(milliseconds: 100));
      expect(lastValue, closeTo(stoppedValue, 0.01));
      c.dispose();
    });

    test('AnimationController reset goes to 0', () {
      final c = AnimationController(duration: const Duration(milliseconds: 100));
      c.reset();
      expect(c.value, closeTo(0.0, 1e-6));
      expect(c.status, AnimationStatus.dismissed);
      c.dispose();
    });

    test('Tween animates between begin and end', () {
      final c = AnimationController(duration: const Duration(milliseconds: 100));
      final tween = Tween<int>(begin: 0, end: 100);
      tween.animate(c);

      int lastValue = 0;
      tween.addListener(() {
        lastValue = tween.value;
      });

      c.forward();
      c.tick(const Duration(milliseconds: 50));
      expect(lastValue, greaterThan(30));
      expect(lastValue, lessThanOrEqualTo(100));

      c.tick(const Duration(milliseconds: 100));
      expect(lastValue, 100);
      c.dispose();
    });

    test('Curve transforms values', () {
      expect(linear.transform(0.0), closeTo(0.0, 1e-6));
      expect(linear.transform(0.5), closeTo(0.5, 1e-6));
      expect(linear.transform(1.0), closeTo(1.0, 1e-6));

      expect(easeIn.transform(0.5), closeTo(0.25, 1e-6));
      expect(easeOut.transform(0.5), closeTo(0.75, 1e-6));
      expect(easeInOut.transform(0.25), closeTo(0.125, 1e-6));
      expect(easeInOut.transform(0.75), closeTo(0.875, 1e-6));
    });

    test('TweenAnimation convenience class', () {
      final ta = TweenAnimation<int>(begin: 0, end: 50);
      int lastValue = 0;
      ta.addListener(() {
        lastValue = ta.value;
      });

      ta.forward();
      ta.controller.tick(const Duration(milliseconds: 50));
      expect(lastValue, greaterThan(0));
      expect(lastValue, lessThanOrEqualTo(50));
      ta.dispose();
    });

    test('Curve modifies animation progression', () {
      final linearCtrl = AnimationController(
        duration: const Duration(milliseconds: 100),
        curve: linear,
      );
      final easeCtrl = AnimationController(
        duration: const Duration(milliseconds: 100),
        curve: easeIn,
      );

      linearCtrl.forward();
      easeCtrl.forward();

      linearCtrl.tick(const Duration(milliseconds: 50));
      easeCtrl.tick(const Duration(milliseconds: 50));

      // At t=0.5, easeIn is slower than linear (0.25 vs 0.5)
      expect(linearCtrl.value, closeTo(0.5, 0.01));
      expect(easeCtrl.value, closeTo(0.25, 0.01));

      linearCtrl.dispose();
      easeCtrl.dispose();
    });
  });
}
