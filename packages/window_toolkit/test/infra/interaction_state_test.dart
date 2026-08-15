import 'package:test/test.dart';
import 'package:window_toolkit/window_toolkit.dart';

class _Probe extends Widget {
  int clicks = 0;

  _Probe() {
    onClick = () {
      clicks++;
      return true;
    };
  }

  @override
  bool get acceptsFocus => true;

  @override
  void draw(Painter canvas) {}
}

ModifierState _mods() =>
    ModifierState(modsDepressed: 0, modsLatched: 0, modsLocked: 0, group: 0);

void main() {
  test(
    'pointer press state lasts until release and click activates on release',
    () {
      final probe = _Probe()
        ..x = 10
        ..y = 10
        ..width = 40
        ..height = 30;
      final window = WidgetWindow(probe);

      window.onMouseButtonPressed(MouseButtonEvent(15, 15, 272, true));
      expect(probe.isPressed, isTrue);
      expect(probe.clicks, 0);

      window.onMouseButtonReleased(MouseButtonEvent(15, 15, 272, false));
      expect(probe.isPressed, isFalse);
      expect(probe.clicks, 1);
    },
  );

  test('release outside cancels activation', () {
    final probe = _Probe()
      ..x = 10
      ..y = 10
      ..width = 40
      ..height = 30;
    final window = WidgetWindow(probe);

    window.onMouseButtonPressed(MouseButtonEvent(15, 15, 272, true));
    window.onMouseButtonReleased(MouseButtonEvent(100, 100, 272, false));

    expect(probe.isPressed, isFalse);
    expect(probe.clicks, 0);
  });

  test('keyboard activation sets pressed state and activates on release', () {
    var presses = 0;
    final button = Button('Run', onPressed: () => presses++);
    final window = WidgetWindow(button);
    window.onMouseButtonPressed(MouseButtonEvent(4, 4, 272, true));
    window.onMouseButtonReleased(MouseButtonEvent(4, 4, 272, false));

    expect(button.isFocused, isTrue);
    presses = 0;
    window.onKeyPressed(KeyEvent(28, true, _mods()));
    expect(button.isPressed, isTrue);
    window.onKeyReleased(KeyEvent(28, false, _mods()));

    expect(button.isPressed, isFalse);
    expect(presses, 1);
  });

  test('disabled controls do not hover, focus, press, or activate', () {
    var presses = 0;
    final button = Button('Disabled', onPressed: () => presses++)
      ..enabled = false;
    final window = WidgetWindow(button);

    window.onMouseMotion(MouseMotionEvent(4, 4));
    window.onMouseButtonPressed(MouseButtonEvent(4, 4, 272, true));
    window.onMouseButtonReleased(MouseButtonEvent(4, 4, 272, false));

    expect(button.isHovered, isFalse);
    expect(button.isFocused, isFalse);
    expect(button.isPressed, isFalse);
    expect(presses, 0);
    expect(button.hasPseudoClass('disabled'), isTrue);
  });

  test('ListBox tracks item hover through the window event path', () {
    final list = ListBox(items: const ['one', 'two'], itemHeight: 20)
      ..x = 0
      ..y = 0
      ..width = 100
      ..height = 40;
    final window = WidgetWindow(list);

    window.onMouseMotion(MouseMotionEvent(10, 25));

    expect(list.hoveredIndex, 1);
    expect(list.isHovered, isTrue);
  });

  test('range slider exposes dragging state during pointer capture', () {
    final slider = RangeSlider()
      ..x = 0
      ..y = 0
      ..width = 160
      ..height = 20;
    final window = WidgetWindow(slider);

    window.onMouseButtonPressed(MouseButtonEvent(30, 10, 272, true));
    expect(slider.hasInteractionState(WidgetState.dragging), isTrue);

    window.onMouseMotion(MouseMotionEvent(80, 10));
    window.onMouseButtonReleased(MouseButtonEvent(80, 10, 272, false));
    expect(slider.hasInteractionState(WidgetState.dragging), isFalse);
  });
}
