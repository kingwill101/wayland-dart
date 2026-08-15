import 'package:test/test.dart';
import 'package:window_toolkit/window_toolkit.dart';

class _ProbeButton extends Button {
  int downs = 0;
  int ups = 0;
  int drags = 0;
  int cancels = 0;
  int keys = 0;

  _ProbeButton(super.text, {super.onPressed});

  @override
  void onMouseDown(int x, int y, int button) => downs++;

  @override
  void onMouseUp(int x, int y, int button) => ups++;

  @override
  void onMouseDrag(int x, int y) => drags++;

  @override
  void onPointerCancel() => cancels++;

  @override
  void onKeyPressed(KeyEvent event) => keys++;
}

void main() {
  test('widget hosts keep repaint ownership local to their tree', () {
    final first = Button('First');
    final second = Button('Second');
    var firstRepaints = 0;
    var secondRepaints = 0;

    WidgetHostController(first, onRepaint: () => firstRepaints++);
    WidgetHostController(second, onRepaint: () => secondRepaints++);

    first.setInteractionState(WidgetState.hovered, true);

    expect(firstRepaints, greaterThan(0));
    expect(secondRepaints, 0);
  });

  test('widget host initializes, lays out, and hit-tests its root tree', () {
    var clicks = 0;
    final button = Button('Open')..x = 10;
    button.onClick = () {
      clicks++;
      return true;
    };
    final row = HBox(children: [button]);
    final root = Container(children: [row]);
    final host = WidgetHostController(root);

    expect(childrenOf(root), contains(same(row)));
    host.layoutRoot(100, 40);
    row.performLayout(100);

    expect(button.mounted, isTrue);
    expect(host.hitTest(12, 8), same(button));
    expect(host.hitTest(90, 35), same(root));
    expect(host.dispatchClick(12, 8), isTrue);
    expect(clicks, 1);
  });

  test('widget host shares press, drag, release, and click routing', () {
    var clicks = 0;
    final button = _ProbeButton('Open', onPressed: () => clicks++);
    final host = WidgetHostController(button);
    host.layoutRoot(120, 40);

    expect(host.dispatchMouseDown(4, 4, 272), isTrue);
    expect(button.isPressed, isTrue);
    expect(button.downs, 1);

    host.dispatchMouseMotion(90, 30);
    expect(button.drags, 1);
    host.dispatchMouseUp(90, 30, 272);
    expect(button.ups, 1);
    expect(button.cancels, 1);
    expect(clicks, 0);
    expect(button.isPressed, isFalse);

    host.dispatchMouseDown(4, 4, 272);
    host.dispatchMouseUp(4, 4, 272);
    expect(clicks, 1);
  });

  test('widget host shares focus, keyboard, and activation routing', () {
    var clicks = 0;
    final button = _ProbeButton('Open', onPressed: () => clicks++);
    final host = WidgetHostController(button);
    host.layoutRoot(120, 40);

    expect(host.dispatchMouseDown(4, 4, 272), isTrue);
    expect(host.focus.focusedWidget, same(button));
    host.dispatchMouseUp(4, 4, 272);

    final modifiers = ModifierState(
      modsDepressed: 0,
      modsLatched: 0,
      modsLocked: 0,
      group: 0,
    );
    host.dispatchKeyPressed(KeyEvent(28, true, modifiers));
    host.dispatchKeyReleased(KeyEvent(28, false, modifiers));

    expect(button.keys, 1);
    expect(clicks, 2);
    expect(button.isPressed, isFalse);
  });
}
