import 'package:test/test.dart';
import 'package:window_toolkit/window_toolkit.dart';

void main() {
  group('ElementHost', () {
    test('wraps StatefulWidget and renders child', () {
      final host = ElementHost(child: _TestCounter());
      host.x = 0;
      host.y = 0;
      host.width = 200;
      host.height = 30;

      final painter = RecordingPainter();
      host.performLayout(200);
      host.draw(painter);

      final texts = painter.commands.ofType<DrawTextCommand>().toList();
      expect(texts, hasLength(1));
      expect(texts[0].text, contains('Count: 0'));
    });

    test('setState triggers rebuild', () {
      final host = ElementHost(child: _TestCounter());
      host.x = 0;
      host.y = 0;
      host.width = 200;
      host.height = 30;
      host.performLayout(200);

      // Find the state and increment
      final element = host.tree?.root;
      expect(element, isNotNull);
      if (element is StatefulElement) {
        final state = element.state as _TestCounterState;
        state.increment();
      }

      // Rebuild
      host.tree?.build();

      final painter = RecordingPainter();
      host.draw(painter);

      final texts = painter.commands.ofType<DrawTextCommand>().toList();
      expect(texts, hasLength(1));
      expect(texts[0].text, contains('Count: 1'));
    });
  });
}

// --- Test widgets ---

class _TestCounter extends StatefulWidget {
  @override
  State createState() => _TestCounterState();
}

class _TestCounterState extends State<_TestCounter> {
  int count = 0;

  void increment() => setState(() => count++);

  @override
  ElementWidget build(BuildContext context) {
    return Label('Count: $count');
  }
}
