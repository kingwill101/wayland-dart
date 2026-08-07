import 'package:window_toolkit/window_toolkit.dart';

void main() {
  // Simulate window min size first paint then resize (the bug)
  final content = VBox(spacing: 6, children: [
    Label('— Layouts —'),
    Padding(all: 8, child: HBox(spacing: 12, children: [
      Button('One'), Button('Two'), Button('Three'),
    ])),
    Padding(all: 8, child: Row(children: [
      Button('Expanded'), Expanded(child: Button('c')), Button('Right'),
    ])),
  ]);
  final scroll = ScrollArea(child: content, showVertical: true);

  // First layout at minWidth (as if window not yet configured)
  scroll
    ..width = 100
    ..height = 60;
  scroll.performLayout(100);
  print('After 100: VBox=${content.width}x${content.height} '
      'Scroll=${scroll.width}x${scroll.height}');

  // Resize to full window
  scroll
    ..width = 1152
    ..height = 648;
  scroll.performLayout(1152);
  print('After 1152: VBox=${content.width}x${content.height} '
      'Scroll=${scroll.width}x${scroll.height}');

  // Fresh layout only at full size
  final content2 = VBox(spacing: 6, children: [
    Label('— Layouts —'),
    Padding(all: 8, child: HBox(spacing: 12, children: [
      Button('One'), Button('Two'), Button('Three'),
    ])),
  ]);
  final scroll2 = ScrollArea(child: content2, showVertical: true)
    ..width = 1152
    ..height = 648;
  scroll2.performLayout(1152);
  print('Fresh 1152: VBox=${content2.width}x${content2.height}');

  // Expanded test
  final a = Button('A');
  final b = Button('B');
  final expChild = Button('fill');
  final exp = Expanded(child: expChild);
  final row = Row(children: [a, exp, b]);
  row.performLayout(400);
  print('Row Expanded: a=${a.width} exp=${exp.width} expChild=${expChild.width} b=${b.width} row=${row.width}');
  
  // ElementHost path like showcase
  final host = ElementHost(child: _Root());
  host
    ..width = 100
    ..height = 60;
  host.performLayout(100);
  print('Host@100: host=${host.width}x${host.height} child=${host.children.first.width}');
  host
    ..width = 1152
    ..height = 648;
  host.performLayout(1152);
  print('Host@1152: host=${host.width}x${host.height} child=${host.children.first.width}');
  final sa = host.children.first;
  if (sa is ScrollArea) {
    print('  ScrollArea child VBox width=${sa.child.width}');
  }
}

class _Root extends StatefulWidget {
  @override
  State createState() => _RootState();
}
class _RootState extends State<_Root> {
  @override
  ElementWidget build(BuildContext context) {
    return ScrollArea(
      showVertical: true,
      child: VBox(spacing: 6, children: [
        Label('header'),
        Padding(all: 8, child: HBox(children: [Button('One'), Button('Two')])),
      ]),
    );
  }
}
