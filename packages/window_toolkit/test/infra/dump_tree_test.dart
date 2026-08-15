import 'package:test/test.dart';
import 'package:window_toolkit/window_toolkit.dart';

void main() {
  test('dumpTree runs without error on Label', () {
    final w = Label('hi');
    w
      ..x = 0
      ..y = 0
      ..width = 40
      ..height = 16;
    expect(() => w.dumpTree(writeln: (_) {}), returnsNormally);
    expect(w.formatTree(), contains('Label'));
    expect(w.formatTree(), contains('40×16'));
  });

  test('dumpTree runs without error on nested VBoxLayout', () {
    final tree = VBoxLayout(
      spacing: 4,
      children: [
        Label('top'),
        Padding(child: Button('ok')),
      ],
    );
    tree
      ..x = 0
      ..y = 0
      ..width = 200
      ..height = 300;
    final text = tree.formatTree();
    expect(text, contains('VBoxLayout'));
    expect(text, contains('Label'));
    expect(text, contains('Button'));
  });

  test('dumpTree runs without error on Flex', () {
    final tree = Row(
      spacing: 8,
      children: [
        Button('A'),
        Expanded(child: Button('B')),
        Button('C'),
      ],
    );
    tree
      ..x = 0
      ..y = 0
      ..width = 200
      ..height = 48;
    expect(tree.formatTree(), contains('Expanded'));
  });

  test('dumpTree runs without error on ScrollArea', () {
    final tree = ScrollArea(child: Label('scrollable'));
    tree
      ..x = 0
      ..y = 0
      ..width = 100
      ..height = 50;
    expect(tree.formatTree(), contains('ScrollArea'));
    expect(tree.formatTree(), contains('Label'));
  });

  test('dumpTree runs without error on Frame', () {
    final tree = Frame(children: [Label('a'), Label('b')]);
    tree
      ..x = 0
      ..y = 0
      ..width = 100
      ..height = 50;
    expect(tree.formatTree(), contains('Frame'));
  });

  test('dumpTree on complex tree with Flex and ScrollArea', () {
    final tree = VBoxLayout(
      spacing: 4,
      children: [
        Label('header'),
        Row(
          children: [
            Button('L'),
            Expanded(child: Button('M')),
            Button('R'),
          ],
        ),
        ScrollArea(
          child: VBoxLayout(
            children: [
              Label('line'),
              Padding(child: Button('ok'), all: 8),
            ],
          ),
        ),
        Frame(children: [Label('a')]),
      ],
    );
    tree
      ..x = 0
      ..y = 0
      ..width = 400
      ..height = 600;
    final text = tree.formatTree();
    expect(text, contains('ScrollArea'));
    expect(text, contains('Expanded'));
  });

  test('uses layout_engine TreeDump formatting', () {
    final row = HBox(children: [Button('A'), Button('B')]);
    row.performLayout(200);
    final text = row.formatTree();
    expect(text.contains('├──') || text.contains('└──'), isTrue);
  });
}
