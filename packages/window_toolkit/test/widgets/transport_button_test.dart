import 'package:test/test.dart';
import 'package:window_toolkit/window_toolkit.dart';

import '../support/widget_test_harness.dart';

void main() {
  test('TransportButton draws a vector control without text glyphs', () {
    final button = TransportButton(TransportAction.play);
    final harness = WidgetHarness(button);

    harness.draw();

    expect(harness.painter.commands.whereType<DrawTextCommand>(), isEmpty);
    expect(harness.painter.commands.whereType<DrawLineCommand>(), hasLength(3));
    expect(harness.painter.commands.whereType<DrawRectCommand>(), hasLength(1));
  });

  test('TransportButton activates through the shared button path', () {
    var pressed = 0;
    final button = TransportButton(
      TransportAction.next,
      onPressed: () => pressed++,
    );

    expect(button.activate(), isTrue);
    expect(pressed, 1);
  });

  test('TransportButton sends hover animation frames to its repaint owner', () {
    var repaints = 0;
    final button = TransportButton(TransportAction.play)
      ..repaintCallback = () => repaints++;

    button.setHovering(true);

    expect(button.isHovered, isTrue);
    expect(repaints, greaterThan(0));
    button.dispose();
  });
}
