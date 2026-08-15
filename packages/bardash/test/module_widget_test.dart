import 'package:test/test.dart';
import 'package:window_toolkit/window_toolkit.dart';
import 'package:bardash/src/module_widget.dart';
import 'package:bardash/src/metrics.dart';
import 'package:bardash/src/modules/module.dart';
import 'package:bardash/src/modules/audio.dart';

class FakeModule extends BarModule {
  @override
  String get name => 'fake';
  @override
  double draw(Painter p, double x, double y) {
    p.drawText(output, Offset(x, y), color: const Color(255, 0, 0));
    return 10;
  }
}

void main() {
  setUp(() {
    BarMetrics.current = BarMetrics.compact;
    FontDatabase.instance.useBitmapEngine();
    StyleContext.reset();
  });
  test('ModuleWidget has styleId and module class', () {
    final m = FakeModule()..output = 'hi';
    final w = ModuleWidget(m);
    expect(w.styleId, 'fake');
    expect(w.hasClass('module'), isTrue);
    expect(w.hasClass('fake'), isTrue);
  });

  test('ordinary modules receive a toolkit text widget', () {
    final m = FakeModule()..output = 'CPU 42%';
    final w = ModuleWidget(m);

    expect(m.widget, isA<TextRuns>());
    expect(w.children, hasLength(1));
    expect(w.children.single, same(m.widget));
    final p = RecordingPainter(width: 800, height: 30);
    w.measure(p);
    expect(w.width, greaterThan(0));
    expect(m.widget!.width, greaterThan(0));
  });

  test('graphics modules keep their custom rendering path', () {
    final m = _GraphicsModule()..output = '';
    final w = ModuleWidget(m);

    expect(m.widget, isNull);
    final p = RecordingPainter(width: 800, height: 30);
    w.measure(p);
    expect(w.width, 12);
  });
  test('ModuleWidget background from CSS', () {
    final provider = CssProvider()
      ..loadFromData('#fake { background-color: #ff0000; }');
    StyleContext.addProviderForScreen(provider);
    final m = FakeModule()
      ..output = 'hi'
      ..paddingLeft = 2
      ..paddingRight = 2;
    final w = ModuleWidget(m)
      ..x = 0
      ..y = 0
      ..width = 100
      ..height = 30;
    final p = RecordingPainter(width: 100, height: 30);
    w.draw(p);
    final bg = p.commands.whereType<DrawRectCommand>().first;
    expect(bg.paint.color.r, 255);
  });
  test('ModuleWidget hover pseudo', () {
    final provider = CssProvider()
      ..loadFromData('#fake:hover { background-color: #00ff00; }');
    StyleContext.addProviderForScreen(provider);
    final m = FakeModule()..output = 'hi';
    final w = ModuleWidget(m)
      ..x = 0
      ..y = 0
      ..width = 100
      ..height = 30;
    w.addPseudoClass('hover');
    final ctx = StyleContext.forWidget(w);
    expect(ctx.parsedBackgroundColor?.g, 255);
  });
  test('ModuleWidget text color from CSS', () {
    final provider = CssProvider()..loadFromData('#fake { color: #0000ff; }');
    StyleContext.addProviderForScreen(provider);
    final m = FakeModule()..output = 'hi';
    final w = ModuleWidget(m)
      ..x = 0
      ..y = 0
      ..width = 100
      ..height = 30;
    final p = RecordingPainter(width: 100, height: 30);
    w.draw(p);
    final txt = p.commands.whereType<DrawTextCommand>().first;
    expect(txt.color?.b, 255);
  });

  test('text module width uses toolkit mixed-font measurement', () {
    final m = AudioModule()..output = '\u{f028} 55%';
    expect(m.showsGraphics, isFalse);
    final w = ModuleWidget(m);
    final p = RecordingPainter(width: 800, height: 30);
    w.measure(p);

    // The icon and percentage must be measured as separate toolkit font runs.
    final full = m.measure(p);
    expect(
      w.width,
      full.round(),
      reason: 'module widget must use the toolkit text-run measure',
    );
    expect(full, greaterThan(0));
  });
}

class _GraphicsModule extends BarModule {
  @override
  String get name => 'graphics-test';

  @override
  bool get showsGraphics => true;

  @override
  double measure(Painter painter) => 12;

  @override
  double draw(Painter painter, double x, double y) => 12;
}
