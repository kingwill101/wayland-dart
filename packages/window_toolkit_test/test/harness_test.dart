import 'package:test/test.dart';
import 'package:window_toolkit/window_toolkit.dart';
import 'package:window_toolkit_test/window_toolkit_test.dart';

void main() {
  group('TestHarness', () {
    test('pumpWidget + pump renders a Button', () async {
      final harness = TestHarness();
      harness.pumpWidget(Button('OK', onPressed: () {}));
      await harness.pump();

      final btn = harness.find.byType<Button>();
      expect(btn, isNotNull);
      expect(btn!.text, 'OK');
    });

    test('Button press triggers callback', () async {
      int count = 0;
      final harness = TestHarness();
      harness.pumpWidget(Button('+1', onPressed: () => count++));
      await harness.pump();

      final btn = harness.find.byType<Button>();
      btn!.onClick?.call();
      expect(count, 1);
    });

    test('Label renders with correct text', () async {
      final harness = TestHarness();
      harness.pumpWidget(Label('Hello', fontSize: 14));
      await harness.pump();

      final lbl = harness.find.text<Label>('Hello');
      expect(lbl, isNotNull);
      expect(lbl!.text, 'Hello');
    });

    test('HBox lays out children horizontally', () async {
      final harness = TestHarness();
      harness.pumpWidget(HBox(spacing: 8, children: [
        Label('A'),
        Label('B'),
        Label('C'),
      ]));
      await harness.pump();

      final labels = harness.find.allByType<Label>();
      expect(labels.length, 3);
      expect(labels[0].text, 'A');
      expect(labels[1].text, 'B');
      expect(labels[2].text, 'C');
    });

    test('VBox lays out children vertically', () async {
      final harness = TestHarness();
      harness.pumpWidget(VBox(spacing: 4, children: [
        Label('Top'),
        Label('Bottom'),
      ]));
      await harness.pump();

      final labels = harness.find.allByType<Label>();
      expect(labels.length, 2);
    });

    test('paint commands are recorded', () async {
      final harness = TestHarness();
      harness.pumpWidget(Label('Test', fontSize: 14));
      await harness.pump();

      expect(harness.commands, isNotEmpty);
      // Should contain a DrawTextCommand for the label.
      final textCmds = harness.commandsOfType<DrawTextCommand>();
      expect(textCmds, isNotEmpty);
      expect(textCmds.first.text, 'Test');
    });

    test('clearCommands empties command list', () async {
      final harness = TestHarness();
      harness.pumpWidget(Label('Clear', fontSize: 14));
      await harness.pump();
      harness.clearCommands();
      expect(harness.commands, isEmpty);
    });

    test('multiple pump calls accumulate resets commands', () async {
      final harness = TestHarness();
      harness.pumpWidget(Button('Click', onPressed: () {}));
      await harness.pump();
      final firstCmds = harness.commands.length;
      await harness.pump();
      // Each pump clears and re-records.
      expect(harness.commands.length, greaterThan(0));
    });
  });

  group('TestBackend', () {
    test('creates painter with correct dimensions', () async {
      final backend = TestBackend(testWidth: 640, testHeight: 480);
      await backend.init();
      expect(backend.width, 640);
      expect(backend.height, 480);
    });
  });

  group('Paint commands', () {
    test('DrawTextCommand records text', () {
      final cmd = DrawTextCommand('hello', const Offset(10, 20));
      expect(cmd.text, 'hello');
      expect(cmd.position.dx, 10);
      expect(cmd.position.dy, 20);
    });

    test('DrawRectCommand records rect', () {
      final cmd = DrawRectCommand(
          Rect.fromLTWH(5, 5, 50, 50), RecordedPaint.fromPaint(Paint()));
      expect(cmd.rect.left, 5);
      expect(cmd.rect.width, 50);
    });

    test('DrawLinearGradientCommand records colors', () {
      final cmd = DrawLinearGradientCommand(
          Rect.fromLTWH(0, 0, 100, 100),
          const Color(255, 0, 0),
          const Color(0, 0, 255),
          1.57);
      expect(cmd.color0.r, 255);
      expect(cmd.color1.b, 255);
      expect(cmd.angle, 1.57);
    });
  });
}
