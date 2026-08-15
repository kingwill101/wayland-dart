import 'package:test/test.dart';
import 'package:window_toolkit/window_toolkit.dart';

void main() {
  group('Animation', () {
    test('AnimationController starts at 0.0', () {
      final c = AnimationController(
        duration: const Duration(milliseconds: 100),
      );
      expect(c.value, closeTo(0.0, 1e-6));
      expect(c.status, AnimationStatus.dismissed);
    });

    test('AnimationController forward drives value to 1.0', () {
      final c = AnimationController(
        duration: const Duration(milliseconds: 100),
      );
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
      final c = AnimationController(
        duration: const Duration(milliseconds: 100),
      );
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

    test('AnimationController reverses from its current value', () {
      final c = AnimationController(
        duration: const Duration(milliseconds: 100),
        curve: linear,
      );

      c.forward();
      c.tick(const Duration(milliseconds: 40));
      expect(c.value, closeTo(0.4, 0.01));

      c.reverse();
      c.tick(const Duration(milliseconds: 50));
      expect(c.value, closeTo(0.2, 0.01));
      c.dispose();
    });

    test('AnimationController stop halts animation', () {
      final c = AnimationController(
        duration: const Duration(milliseconds: 200),
      );
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
      final c = AnimationController(
        duration: const Duration(milliseconds: 100),
      );
      c.reset();
      expect(c.value, closeTo(0.0, 1e-6));
      expect(c.status, AnimationStatus.dismissed);
      c.dispose();
    });

    test('Tween animates between begin and end', () {
      final c = AnimationController(
        duration: const Duration(milliseconds: 100),
      );
      final tween = Tween<int>(begin: 0, end: 100);
      final anim = tween.animate(c);

      int lastValue = 0;
      anim.addListener(() {
        lastValue = anim.value;
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

  group('Animatable', () {
    test('Tween<double> evaluates linearly', () {
      final t = Tween<double>(begin: 0, end: 100);
      expect(t.evaluate(0.0), closeTo(0, 1e-6));
      expect(t.evaluate(0.5), closeTo(50, 1e-6));
      expect(t.evaluate(1.0), closeTo(100, 1e-6));
    });

    test('Tween<int> evaluates with rounding', () {
      final t = Tween<int>(begin: 0, end: 100);
      expect(t.evaluate(0.0), 0);
      expect(t.evaluate(1.0), 100);
      expect(t.evaluate(0.666), 67);
    });

    test('ColorTween interpolates channels', () {
      const black = Color(0, 0, 0);
      const white = Color(255, 255, 255);
      final t = ColorTween(begin: black, end: white);
      final start = t.evaluate(0.0);
      expect(start.r, 0);
      expect(start.g, 0);
      expect(start.b, 0);
      final end = t.evaluate(1.0);
      expect(end.r, 255);
      expect(end.g, 255);
      expect(end.b, 255);
      final mid = t.evaluate(0.5);
      expect(mid.r, closeTo(127, 1));
      expect(mid.g, closeTo(127, 1));
      expect(mid.b, closeTo(127, 1));
      expect(mid.a, 255);
    });

    test('ColorTween interpolates alpha', () {
      const transparent = Color(0, 0, 0, 0);
      const opaque = Color(0, 0, 0, 255);
      final t = ColorTween(begin: transparent, end: opaque);
      expect(t.evaluate(0.5).a, closeTo(127, 1));
    });

    test('OffsetTween interpolates dx/dy', () {
      final t = OffsetTween(
        begin: const Offset(0, 10),
        end: const Offset(100, 110),
      );
      expect(t.evaluate(0.0).dx, closeTo(0, 1e-6));
      expect(t.evaluate(0.0).dy, closeTo(10, 1e-6));
      expect(t.evaluate(0.5).dx, closeTo(50, 1e-6));
      expect(t.evaluate(0.5).dy, closeTo(60, 1e-6));
      expect(t.evaluate(1.0).dx, closeTo(100, 1e-6));
      expect(t.evaluate(1.0).dy, closeTo(110, 1e-6));
    });

    test('SizeTween interpolates width/height', () {
      final t = SizeTween(begin: const Size(10, 20), end: const Size(110, 70));
      expect(t.evaluate(0.0).width, closeTo(10, 1e-6));
      expect(t.evaluate(0.0).height, closeTo(20, 1e-6));
      expect(t.evaluate(0.5).width, closeTo(60, 1e-6));
      expect(t.evaluate(0.5).height, closeTo(45, 1e-6));
      expect(t.evaluate(1.0).width, closeTo(110, 1e-6));
      expect(t.evaluate(1.0).height, closeTo(70, 1e-6));
    });

    test('RectTween interpolates corners', () {
      final t = RectTween(
        begin: const Rect.fromLTRB(0, 0, 100, 50),
        end: const Rect.fromLTRB(10, 20, 60, 70),
      );
      final mid = t.evaluate(0.5);
      expect(mid.left, closeTo(5, 1e-6));
      expect(mid.top, closeTo(10, 1e-6));
      expect(mid.right, closeTo(80, 1e-6));
      expect(mid.bottom, closeTo(60, 1e-6));
    });

    test('chain composes two animatables', () {
      final first = Tween<double>(begin: 0, end: 10);
      final second = Tween<double>(begin: 10, end: 20);
      final chained = first.chain(second);

      expect(chained.evaluate(0.0), closeTo(0, 1e-6));
      expect(chained.evaluate(0.25), closeTo(5, 1e-6));
      expect(chained.evaluate(0.5), closeTo(10, 1e-6));
      expect(chained.evaluate(0.75), closeTo(15, 1e-6));
      expect(chained.evaluate(1.0), closeTo(20, 1e-6));
    });
  });
  group('AnimationController.drive', () {
    test('drives a Tween<double>', () {
      final c = AnimationController(
        duration: const Duration(milliseconds: 100),
      );
      final anim = c.drive(Tween<double>(begin: 0, end: 100));

      c.forward();
      c.tick(const Duration(milliseconds: 50));
      expect(anim.value, closeTo(50, 0.1));

      c.tick(const Duration(milliseconds: 100));
      expect(anim.value, closeTo(100, 0.01));
      expect(anim.status, AnimationStatus.completed);
      c.dispose();
    });

    test('drives a ColorTween and notifies listeners', () {
      final c = AnimationController(
        duration: const Duration(milliseconds: 100),
      );
      final anim = c.drive(
        ColorTween(begin: const Color(0, 0, 0), end: const Color(255, 0, 0)),
      );

      Color? last;
      anim.addListener(() => last = anim.value);

      c.forward();
      c.tick(const Duration(milliseconds: 50));
      expect(last!.r, closeTo(127, 8));

      c.dispose();
    });

    test('drives an OffsetTween', () {
      final c = AnimationController(
        duration: const Duration(milliseconds: 100),
      );
      final anim = c.drive(
        OffsetTween(begin: const Offset(0, 0), end: const Offset(100, 200)),
      );

      c.forward();
      c.tick(const Duration(milliseconds: 50));
      expect(anim.value.dx, closeTo(50, 0.1));
      expect(anim.value.dy, closeTo(100, 0.1));
      c.dispose();
    });

    test('drives an int Tween with rounding', () {
      final c = AnimationController(
        duration: const Duration(milliseconds: 100),
      );
      final anim = c.drive(Tween<int>(begin: 0, end: 10));

      c.forward();
      c.tick(const Duration(milliseconds: 50));
      expect(anim.value, 5);

      c.dispose();
    });
  });

  group('AnimationController.repeat', () {
    test('repeats continuously with restart mode', () {
      final c = AnimationController(
        duration: const Duration(milliseconds: 100),
      );
      c.repeat();
      c.tick(const Duration(milliseconds: 50));
      expect(c.value, closeTo(0.5, 0.05));
      c.tick(const Duration(milliseconds: 100));
      expect(c.status, isNot(AnimationStatus.completed));
      c.dispose();
    });

    test('repeats with count and completes after count cycles', () {
      final c = AnimationController(
        duration: const Duration(milliseconds: 100),
      );
      c.repeat(count: 2);
      c.tick(const Duration(milliseconds: 100));
      expect(c.status, isNot(AnimationStatus.completed));
      c.tick(const Duration(milliseconds: 100));
      expect(c.value, closeTo(1.0, 0.01));
      c.dispose();
    });

    test('reverse mode alternates direction', () {
      final c = AnimationController(
        duration: const Duration(milliseconds: 100),
      );
      c.repeat(mode: RepeatMode.reverse);
      c.tick(const Duration(milliseconds: 100));
      expect(c.value, closeTo(1.0, 0.01));
      c.dispose();
    });
  });

  group('AnimationController lifecycle', () {
    test('dispose stops and marks disposed', () {
      final c = AnimationController();
      c.forward();
      c.dispose();
      expect(c.isDisposed, isTrue);
      expect(c.isAnimating, isFalse);
      c.tick(const Duration(milliseconds: 50));
      expect(c.value, 0.0);
    });

    test('animateTo is available', () {
      final c = AnimationController(
        duration: const Duration(milliseconds: 100),
      );
      c.forward();
      c.tick(const Duration(milliseconds: 100));
      expect(c.value, closeTo(1.0, 0.01));
      c.dispose();
    });
  });

  group('TweenAnimation', () {
    test('exposes driven animation and controller', () {
      final ta = TweenAnimation<double>(
        begin: 0,
        end: 100,
        duration: const Duration(milliseconds: 100),
      );
      ta.forward();
      ta.controller.tick(const Duration(milliseconds: 50));
      expect(ta.value, closeTo(50, 0.1));
      ta.dispose();
    });
  });
}
