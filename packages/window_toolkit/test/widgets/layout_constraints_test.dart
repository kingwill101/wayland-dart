/// Regression tests for constraint-based layout in window_toolkit.
///
/// These guard against the class of bugs where widgets "stick" to a previous
/// frame's width (e.g. window minWidth=100) after the parent grows, or where
/// Expanded/Flexible never receive flex space because FlexParentData was not
/// wired into layout_engine.
library;
import 'package:test/test.dart';
import 'package:window_toolkit/window_toolkit.dart';

void main() {
  group('constraint growth (no sticky width)', () {
    test('ScrollArea child expands when viewport grows after small first layout',
        () {
      final content = VBox(spacing: 6, children: [
        Label('header'),
        Padding(
          all: 8,
          child: HBox(spacing: 12, children: [
            Button('One'),
            Button('Two'),
            Button('Three'),
          ]),
        ),
      ]);
      final scroll = ScrollArea(child: content, showVertical: true);

      // First paint at WidgetWindow.minWidth (common before configure).
      scroll
        ..width = 100
        ..height = 60;
      scroll.performLayout(100);
      expect(content.width, 100);

      // Resize to a real window size — content must grow with the viewport.
      scroll
        ..width = 1152
        ..height = 648;
      scroll.performLayout(1152);

      expect(scroll.width, 1152);
      expect(content.width, 1152,
          reason: 'VBox under ScrollArea must not stick to prior 100px width');
    });

    test('VBox children stretch to full container width after resize', () {
      final pad = Padding(all: 8, child: HBox(children: [Button('One')]));
      final vbox = VBox(children: [Label('title'), pad]);

      vbox.performLayout(100);
      expect(vbox.width, 100);
      expect(pad.width, 100);

      vbox.performLayout(800);
      expect(vbox.width, 800);
      expect(pad.width, 800,
          reason: 'Padding under VBox must stretch with parent');
      expect(pad.child.width, 800 - 16,
          reason: 'HBox inside padding gets inner width');
    });

    test('ElementHost + ScrollArea + VBox expands on second layout', () {
      final host = ElementHost(child: _ShowcaseLikeRoot());
      host
        ..width = 100
        ..height = 60;
      host.performLayout(100);

      host
        ..width = 1152
        ..height = 648;
      host.performLayout(1152);

      expect(host.width, 1152);
      final scroll = host.children.first;
      expect(scroll, isA<ScrollArea>());
      expect(scroll.width, 1152);
      expect((scroll as ScrollArea).child.width, 1152,
          reason: 'Showcase-style tree must fill window after resize');
    });

    test('Padding fills offered width rather than shrinking to child', () {
      final btn = Button('X');
      final pad = Padding(all: 8, child: btn);
      pad.performLayout(400);
      expect(pad.width, 400);
      expect(btn.width, lessThan(400)); // intrinsic button
      expect(btn.width, greaterThan(0));
    });
  });

  group('flex / Expanded', () {
    test('Expanded takes remaining space in a Row', () {
      final a = Button('A');
      final fill = Button('fill');
      final exp = Expanded(child: fill);
      final b = Button('B');
      final row = Row(children: [a, exp, b]);

      row.performLayout(400);

      expect(row.width, 400);
      expect(a.width, greaterThan(0));
      expect(b.width, greaterThan(0));
      expect(exp.width, 400 - a.width - b.width,
          reason: 'Expanded must receive leftover main-axis space');
      expect(fill.width, exp.width,
          reason: 'Expanded must sync bounds into its child');
      expect(a.x, lessThan(exp.x));
      expect(exp.x, lessThan(b.x));
    });

    test('flex factors distribute space proportionally', () {
      final left = Expanded(flex: 1, child: Button('L'));
      final right = Expanded(flex: 3, child: Button('R'));
      final row = Row(children: [left, right]);
      row.performLayout(400);

      // 1:3 split of full width (no non-flex siblings).
      expect(left.width, closeTo(100, 1));
      expect(right.width, closeTo(300, 1));
    });

    test('HBox keeps button intrinsic widths while filling container', () {
      final one = Button('One');
      final two = Button('Two');
      final hbox = HBox(spacing: 12, children: [one, two]);
      hbox.performLayout(500);

      expect(hbox.width, 500);
      expect(one.width, lessThan(100));
      expect(two.width, lessThan(100));
      expect(one.x + one.width, lessThanOrEqualTo(two.x));
    });
  });

  group('leaf intrinsic sizing', () {
    test('Button.performLayout does not expand to fill container', () {
      final btn = Button('Hi');
      final before = btn.width;
      btn.performLayout(1000);
      expect(btn.width, before,
          reason: 'Buttons stay content-sized unless Expanded/SizedBox');
    });

    test('Button.performLayout clamps when container is smaller than intrinsic',
        () {
      final btn = Button('Longer Button');
      expect(btn.width, greaterThan(20));
      btn.performLayout(20);
      expect(btn.width, 20);
    });

    test('Wrap children recover full width after narrow then wide layout', () {
      final buttons = [
        Button('Alpha'),
        Button('Beta'),
        Button('Longer Button'),
      ];
      final wrap = WrapLayout(
        spacing: 10,
        runSpacing: 10,
        children: buttons,
      );
      final pad = Padding(all: 8, child: wrap);
      final vbox = VBox(children: [pad]);

      vbox.performLayout(100);
      expect(buttons[2].width, lessThan(100));

      vbox.performLayout(500);
      expect(buttons[0].width, greaterThan(40),
          reason: 'Alpha must recover intrinsic after narrow clamp');
      expect(buttons[2].width, greaterThan(80),
          reason: 'Longer Button must recover intrinsic after narrow clamp');
      // On a wide row, Longer Button should sit to the right of Alpha.
      expect(buttons[2].x, greaterThan(buttons[0].x));
    });
  });
}

/// Mirrors example/widgets/showcase.dart root structure.
class _ShowcaseLikeRoot extends StatefulWidget {
  @override
  State createState() => _ShowcaseLikeRootState();
}

class _ShowcaseLikeRootState extends State<_ShowcaseLikeRoot> {
  @override
  ElementWidget build(BuildContext context) {
    return ScrollArea(
      showVertical: true,
      child: VBox(spacing: 6, children: [
        Label('— Layouts —'),
        Padding(
          all: 8,
          child: HBox(spacing: 12, children: [
            Button('One'),
            Button('Two'),
            Button('Three'),
          ]),
        ),
        Padding(
          all: 8,
          child: Row(children: [
            Button('Left'),
            Expanded(child: Button('c')),
            Button('Right'),
          ]),
        ),
      ]),
    );
  }
}
