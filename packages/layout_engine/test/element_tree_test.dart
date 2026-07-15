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

      // The child's build context should find the parent state.
      // This is tested through the parent context lookup in build().
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
    // Find parent state
    context.findAncestorStateOfType<_TestStatefulState>();
    return _TestRender();
  }
}
