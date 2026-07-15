import 'package:test/test.dart';
import 'package:window_toolkit/window_toolkit.dart';

import '../support/widget_test_harness.dart';

void main() {
  test('ContextMenu shows and hides', () {
    final cm = ContextMenu(items: [MenuItem('Copy'), MenuItem('Paste')]);
    expect(cm.visible, isFalse);

    cm.show(100, 50);
    expect(cm.visible, isTrue);
    expect(cm.targetX, 100);
    expect(cm.targetY, 50);

    cm.hide();
    expect(cm.visible, isFalse);
  });

  test('ContextMenu draws when visible', () {
    final cm = ContextMenu(
      items: [
        MenuItem('Copy', onTriggered: () {}),
        MenuItem('Paste'),
      ],
      visible: true,
      targetX: 10,
      targetY: 10,
    );

    final painter = RecordingPainter();
    cm.draw(painter);
    expect(painter.commands, isNotEmpty);
  });
}
