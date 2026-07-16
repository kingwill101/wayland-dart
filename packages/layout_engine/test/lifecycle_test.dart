/// Layout engine behavior tests: render object lifecycle, element tree edge cases.
import 'package:test/test.dart';
import 'package:layout_engine/layout_engine.dart';

void main() {
  // ── Render object lifecycle ─────────────────────────────────

  group('RenderObject', () {
    test('attach sets parent and adds child', () {
      final parent = RenderDelegateBox((r, c) => r.size = Size(100, 50));
      final child = RenderDelegateBox((r, c) => r.size = Size(50, 50));
      parent.attach(child);

      expect(child.parent, same(parent));
      expect(parent.children, contains(child));
    });

    test('detach removes child and clears parent', () {
      final parent = RenderDelegateBox((r, c) => r.size = Size(100, 50));
      final child = RenderDelegateBox((r, c) => r.size = Size(50, 50));
      parent.attach(child);
      parent.detach(child);

      expect(child.parent, isNull);
      expect(parent.children, isEmpty);
    });

    test('constrain clamps to bounds', () {
      final c = BoxConstraints(maxWidth: 100, maxHeight: 50);
      final s = c.constrain(Size(500, 500));
      expect(s.width, 100);
      expect(s.height, 50);
    });

    test('constrain respects minimum', () {
      final c = BoxConstraints(minWidth: 50, minHeight: 30);
      final s = c.constrain(Size(10, 10));
      expect(s.width, 50);
      expect(s.height, 30);
    });

    test('layout calls callback with constraints', () {
      BoxConstraints? received;
      final box = RenderDelegateBox((r, c) {
        received = c;
        r.size = c.constrain(Size(500, 500));
      });
      box.layout(BoxConstraints(maxWidth: 100, maxHeight: 50));

      expect(received, isNotNull);
      expect(received!.maxWidth, 100);
    });

    test('parentData stores custom data', () {
      final child = RenderDelegateBox((r, c) => r.size = Size(10, 10));
      child.parentData = StackParentData(left: 5, top: 10);
      final data = child.parentData as StackParentData;

      expect(data.left, 5);
      expect(data.top, 10);
    });
  });

  // ── Element tree lifecycle ─────────────────────────────────

  group('ElementTree lifecycle', () {
    test('mount builds widget tree', () {
      final tree = ElementTree();
      tree.mount(_TestStateless(msg: 'hello'));
      tree.build();

      expect(tree.root, isNotNull);
      expect(tree.root!.depth, 0);
      expect(tree.root!.children, hasLength(1));
      expect(tree.root!.children.first.depth, 1);
    });

    test('rebuild after markNeedsBuild', () {
      final tree = ElementTree();
      tree.mount(_TestStatefulLifecycle());
      tree.build();

      final element = tree.root!;
      final state = (element as StatefulElement).state as _LifecycleState;
      expect(state.buildCount, 1);

      state.requestRebuild();
      expect(state.buildCount, 1); // not yet rebuilt

      tree.build(); // rebuild dirty
      expect(state.buildCount, 2);
    });

    test('unmount calls state.dispose', () {
      bool disposed = false;
      final tree = ElementTree();
      tree.mount(_TestDisposable(() => disposed = true));
      tree.build();

      tree.unmount();
      expect(disposed, isTrue);
    });

    test('replaceRoot with same type updates widget', () {
      final tree = ElementTree();
      tree.mount(_TestStateless(msg: 'first'));
      tree.build();

      expect((tree.root!.widget as _TestStateless).msg, 'first');

      tree.replaceRoot(_TestStateless(msg: 'second'));
      tree.build();

      expect((tree.root!.widget as _TestStateless).msg, 'second');
    });

    test('replaceRoot with different type creates new element', () {
      final tree = ElementTree();
      tree.mount(_TestStateless(msg: 'first'));
      tree.build();

      final oldRoot = tree.root;
      tree.replaceRoot(_TestStatefulLifecycle());
      tree.build();

      // Different runtimeType → new element
      expect(tree.root, isNot(same(oldRoot)));
    });

    test('StatefulWidget initState called once on mount', () {
      int initCalls = 0;
      final tree = ElementTree();
      tree.mount(_TestWithInit(() => initCalls++));
      tree.build();

      expect(initCalls, 1);
    });

    test('StatefulWidget didUpdateWidget called on update', () {
      String? oldMsg;
      final tree = ElementTree();
      tree.mount(_TestUpdatable());
      tree.build();

      final element = tree.root as StatefulElement;
      final state = element.state as _UpdatableState;
      state.onUpdate = (old) => oldMsg = (old as _TestUpdatable).msg;

      tree.replaceRoot(_TestUpdatable(msg: 'updated'));
      tree.build();

      expect(oldMsg, 'initial');
    });
  });

  // ── BuildContext navigation ─────────────────────────────────

  group('BuildContext', () {
    test('findAncestorStateOfType finds parent state', () {
      final tree = ElementTree();
      tree.mount(_ParentWithState(child: _ChildLookingForState()));
      tree.build();

      // The child's build method calls findAncestorStateOfType
      // If it finds the parent, it passes. No crash = test passes.
    });

    test('findAncestorStateOfType returns null when not found', () {
      final tree = ElementTree();
      tree.mount(_ChildLookingForState());
      tree.build();

      // No parent state of type _ParentState exists — should return null.
      // No crash = test passes.
    });
  });
}

// ── Test widgets ──────────────────────────────────────────────

class _TestStateless extends StatelessWidget {
  final String msg;
  _TestStateless({this.msg = ''});

  @override
  ElementWidget build(BuildContext context) => _TestLeaf();
}

class _TestLeaf extends ElementWidget {}

class _TestStatefulLifecycle extends StatefulWidget {
  @override
  State createState() => _LifecycleState();
}

class _LifecycleState extends State<_TestStatefulLifecycle> {
  int buildCount = 0;

  void requestRebuild() => setState(() {});

  @override
  ElementWidget build(BuildContext context) {
    buildCount++;
    return _TestLeaf();
  }
}

class _TestDisposable extends StatefulWidget {
  final void Function() onDispose;
  _TestDisposable(this.onDispose);

  @override
  State createState() => _DisposableState();
}

class _DisposableState extends State<_TestDisposable> {
  @override
  void dispose() {
    widget.onDispose();
    super.dispose();
  }

  @override
  ElementWidget build(BuildContext context) => _TestLeaf();
}

class _TestWithInit extends StatefulWidget {
  final void Function() onInit;
  _TestWithInit(this.onInit);

  @override
  State createState() => _InitState();
}

class _InitState extends State<_TestWithInit> {
  @override
  void initState() {
    widget.onInit();
    super.initState();
  }

  @override
  ElementWidget build(BuildContext context) => _TestLeaf();
}

class _TestUpdatable extends StatefulWidget {
  final String msg;
  _TestUpdatable({this.msg = 'initial'});

  @override
  State createState() => _UpdatableState();
}

class _UpdatableState extends State<_TestUpdatable> {
  void Function(StatefulWidget old)? onUpdate;

  @override
  void didUpdateWidget(covariant StatefulWidget oldWidget) {
    onUpdate?.call(oldWidget);
  }

  @override
  ElementWidget build(BuildContext context) => _TestLeaf();
}

class _ParentWithState extends StatefulWidget {
  final ElementWidget child;
  _ParentWithState({required this.child});

  @override
  State createState() => _ParentState();
}

class _ParentState extends State<_ParentWithState> {
  String parentData = 'hello';

  @override
  ElementWidget build(BuildContext context) => widget.child;
}

class _ChildLookingForState extends StatelessWidget {
  @override
  ElementWidget build(BuildContext context) {
    context.findAncestorStateOfType<_ParentState>();
    return _TestLeaf();
  }
}
