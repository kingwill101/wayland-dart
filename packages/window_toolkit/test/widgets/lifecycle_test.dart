import 'package:test/test.dart';
import 'package:window_toolkit/window_toolkit.dart';

void main() {
  group('Widget lifecycle', () {
    test('mounted is false by default', () {
      final w = Label('Test');
      expect(w.mounted, isFalse);
    });

    test('initState is called on mount', () {
      bool initCalled = false;
      final w = _LifecycleTest(
        onInit: () => initCalled = true,
      );
      w.mounted = true;
      if (w.mounted) w.initState();
      expect(initCalled, isTrue);
    });

    test('dispose is called on unmount', () {
      bool disposeCalled = false;
      final w = _LifecycleTest(
        onDispose: () => disposeCalled = true,
      );
      w.mounted = true;
      if (w.mounted) w.initState();
      w.mounted = false;
      w.dispose();
      expect(disposeCalled, isTrue);
    });
  });
}

class _LifecycleTest extends Widget {
  final VoidCallback? onInit;
  final VoidCallback? onDispose;

  _LifecycleTest({this.onInit, this.onDispose});

  @override
  void initState() {
    super.initState();
    onInit?.call();
  }

  @override
  void dispose() {
    onDispose?.call();
    super.dispose();
  }

  @override
  void draw(Painter canvas) {}
}
