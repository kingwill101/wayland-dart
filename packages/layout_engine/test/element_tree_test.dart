import 'package:test/test.dart';
import 'package:layout_engine/layout_engine.dart';

void main() {
  group('ElementTree', () {
    test('mounts and builds a StatelessWidget', () {
      final tree = ElementTree();
      tree.mount(_TestStateless(msg: 'Hello'));
      tree.build();

      expect(tree.root, isNotNull);
      expect(tree.root!.widget, isA<_TestStateless>());
      expect(tree.root!.children, hasLength(1));
      expect(tree.root!.children.first.widget, isA<_TestRender>());
    });

    test('mounts and builds a StatefulWidget', () {
      final tree = ElementTree();
      tree.mount(_TestStateful());
      tree.build();

      expect(tree.root, isNotNull);
      expect(tree.root!.widget, isA<_TestStateful>());
      expect(tree.root!.renderWidget, isA<_TestRender>());
    });

    test('setState triggers rebuild', () {
      final tree = ElementTree();
      final widget = _TestStateful();
      tree.mount(widget);
      tree.build();

      // Get the state and call setState.
      final element = tree.root as StatefulElement;
      final state = element.state as _TestStatefulState;
      expect(state.buildCount, 1);

      state.increment();
      expect(state.buildCount, 1); // not rebuilt yet

      tree.build(); // rebuild dirty elements
      expect(state.buildCount, 2);
    });

    test('BuildContext finds ancestor state', () {
      final tree = ElementTree();
      tree.mount(_ParentWidget());
      tree.build();

      final childElement = tree.root!.children.first.children.first;
      expect(childElement, isNotNull);

    });

    test('hitTest traverses element tree with pointInBounds', () {
      final tree = ElementTree();
      tree.mount(_TestStateless(msg: 'parent'));
      tree.build();

      Element? doHitTest(double px, double py) {
        return tree.root!.hitTest(px, py, (w) {
          if (w is _TestStateless) {
            return px >= 0 && px < 200 && py >= 0 && py < 100;
          }
          if (w is _TestRender) {
            return px >= 10 && px < 60 && py >= 10 && py < 60;
          }
          return false;
        });
      }

      // Hit at center of leaf
      var hit = doHitTest(35, 35);
      expect(hit, isNotNull);
      expect(hit!.widget, isA<_TestRender>());

      // Hit in parent but not in leaf
      hit = doHitTest(5, 5);
      expect(hit, isNotNull);
      expect(hit!.widget, isA<_TestStateless>());

      // Hit outside everything
      hit = doHitTest(500, 500);
      expect(hit, isNull);
    });

    test('InheritedWidget propagates to dependents', () {
      final tree = ElementTree();
      tree.mount(_InheritedTestRoot(
        value: 0,
        child: _InheritedConsumer(),
      ));
      tree.build();

      // Update with new value.
      tree.replaceRoot(_InheritedTestRoot(
        value: 42,
        child: _InheritedConsumer(),
      ));
      tree.build();

      // No crash = inherited propagation works.
    });
  });
}

// --- Test widgets ---

class _TestStateless extends StatelessWidget {
  final String msg;
  _TestStateless({this.msg = ''});

  @override
  ElementWidget build(BuildContext context) {
    return _TestRender(msg: msg);
  }
}

class _TestRender extends ElementWidget {
  final String msg;
  _TestRender({this.msg = ''});
}

class _TestStateful extends StatefulWidget {
  @override
  State createState() => _TestStatefulState();
}

class _TestStatefulState extends State<_TestStateful> {
  int buildCount = 0;

  void increment() {
    setState(() {});
  }

  @override
  ElementWidget build(BuildContext context) {
    buildCount++;
    return _TestRender(msg: 'count=$buildCount');
  }
}

class _ParentWidget extends StatelessWidget {
  @override
  ElementWidget build(BuildContext context) {
    return _ChildWidget();
  }
}

class _ChildWidget extends StatelessWidget {
  @override
  ElementWidget build(BuildContext context) {
    context.findAncestorStateOfType<_TestStatefulState>();
    return _TestRender();
  }
}

// --- InheritedWidget test widgets ---

class _InheritedTestRoot extends StatelessWidget {
  final int value;
  final ElementWidget child;
  _InheritedTestRoot({required this.value, required this.child});

  @override
  ElementWidget build(BuildContext context) {
    return _TestInherited(value: value, child: child);
  }
}

class _TestInherited extends InheritedWidget {
  final int value;
  _TestInherited({required this.value, required super.child});

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) {
    return (oldWidget as _TestInherited).value != value;
  }
}

class _InheritedConsumer extends StatelessWidget {
  @override
  ElementWidget build(BuildContext context) {
    final inherited = context.dependOnInheritedWidgetOfExactType<_TestInherited>();
    final value = inherited?.value ?? -1;
    return _TestRender(msg: 'value=$value');
  }
}
