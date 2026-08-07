import 'package:test/test.dart';
import 'package:layout_engine/layout_engine.dart';

class _Fixed extends RenderBox {
  _Fixed(this.w, this.h);
  final double w;
  final double h;

  @override
  void layout(BoxConstraints constraints) {
    this.constraints = constraints;
    size = constraints.constrain(Size(w, h));
  }
}

void main() {
  group('TreeDump', () {
    test('formats a simple tree', () {
      final text = TreeDump.format(
        label: 'root',
        children: ['a', 'b'],
        labelOf: (n) => n as String,
        childrenOf: (_) => const [],
      );
      expect(text, contains('root'));
      expect(text, contains('├── a'));
      expect(text, contains('└── b'));
    });

    test('bounds helpers', () {
      expect(
        TreeDump.boundsInt(x: 1, y: 2, width: 3, height: 4),
        '(1,2) 3×4',
      );
      expect(
        TreeDump.bounds(x: 0, y: 0, width: 10, height: 20),
        '(0,0) 10×20',
      );
    });
  });

  group('RenderObject dump', () {
    test('dumpRenderTree / formatRenderTree', () {
      final row = RenderRow(gap: 4, mainAxisSize: MainAxisSize.max);
      final a = _Fixed(30, 20);
      final b = _Fixed(50, 20)
        ..parentData = const FlexParentData(flex: 1);
      row
        ..attach(a)
        ..attach(b);
      row.layout(const BoxConstraints(maxWidth: 200, maxHeight: 100));

      final text = formatRenderTree(row);
      expect(text, contains('RenderRow'));
      expect(text, contains('flex=1'));
      expect(text, contains('_Fixed'));

      final lines = <String>[];
      row.dumpTree(writeln: lines.add);
      expect(lines, isNotEmpty);
      expect(lines.first, contains('RenderRow'));
    });
  });

  group('Element dump', () {
    test('dumpElementTree shows widget types', () {
      final tree = ElementTree()..mount(_Root());
      tree.build();
      final root = tree.root!;
      final text = formatElementTree(root);
      expect(text, contains('_Root'));
      expect(text, contains('_LeafConfig'));
    });
  });
}

class _Root extends StatelessWidget {
  @override
  ElementWidget build(BuildContext context) => _LeafConfig();
}

/// Leaf configuration (no further build).
class _LeafConfig extends ElementWidget {
  const _LeafConfig();
}
