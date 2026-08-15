import 'package:test/test.dart';
import 'package:window_toolkit/window_toolkit.dart';
import 'package:bardash/src/module_widget.dart';
import 'package:bardash/src/metrics.dart';
import 'package:bardash/src/modules/module.dart';
import 'package:bardash/src/modules/audio.dart';
import 'package:bardash/src/modules/registry.dart';

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

  test('composite modules expose toolkit widget trees', () {
    final cases = <String, Map<String, String>>{
      'cpu/graph': {},
      'custom/graph': {'exec': 'echo 1'},
      'pulseaudio-slider': {},
      'backlight-slider': {},
      'group/test': {'modules': 'clock,cpu'},
    };

    for (final entry in cases.entries) {
      final module = createModule(entry.key);
      expect(module, isNotNull, reason: entry.key);
      module!.init(entry.value);

      final wrapper = ModuleWidget(module);
      expect(
        module.widget,
        isNotNull,
        reason: '${entry.key} should be composed from toolkit widgets',
      );
      expect(wrapper.children, hasLength(1), reason: entry.key);
    }
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

  test('text module width uses the shared toolkit text widget', () {
    final m = AudioModule()..output = '\u{f028} 55%';
    expect(m.showsGraphics, isFalse);
    final w = ModuleWidget(m);
    final p = RecordingPainter(width: 800, height: 30);
    w.measure(p);

    expect(m.widget, isA<TextRuns>());
    expect(w.width, greaterThan(0));
    expect((m.widget as TextRuns).width, greaterThan(0));
  });

  test('dynamically rebuilt module controls receive toolkit hover state', () {
    final first = Button('1');
    final m = _WidgetModule(first);
    final wrapper = ModuleWidget(m);
    final host = WidgetHostController(wrapper);

    host.layoutRoot(200, 30);
    final replacement = Button('2');
    m.widget = replacement;
    host.layoutRoot(200, 30);
    host.updateHover(4, 4);

    // Hyprland workspace buttons are rebuilt in exactly this way when the
    // IPC event stream reports a workspace change.
    expect(replacement.mounted, isTrue);
    expect(replacement.isHovered, isTrue);
    expect(replacement.hasPseudoClass('hover'), isTrue);
  });

  test('module CSS color inherits into a composite toolkit child', () {
    final provider = CssProvider()
      ..loadFromData('#widget-test { color: #89b4fa; font-size: 18px; }');
    StyleContext.addProviderForScreen(provider);
    final child = TextRuns('hello');
    final m = _WidgetModule(child);
    final wrapper = ModuleWidget(m)
      ..x = 0
      ..y = 0
      ..width = 120
      ..height = 30;
    final p = RecordingPainter(width: 120, height: 30);

    wrapper.draw(p);

    expect(child.parent, same(wrapper));
    expect(child.resolvedStyle().color.r, 0x89);
    expect(child.resolvedStyle().color.b, 0xfa);
    expect(child.resolvedStyle().fontSize, 18);
  });

  test('legacy graphics colors consume the same concrete module style', () {
    final m = _GraphicsModule()
      ..cssStyle = const Style(
        color: Color(20, 30, 40),
        backgroundColor: Color(1, 2, 3),
        borderColor: Color(50, 60, 70),
        opacity: 0.5,
      );

    final ink = m.cssColor(const Color(255, 255, 255));
    final border = m.cssColor(const Color(255, 255, 255), border: true);

    expect(ink.r, 20);
    expect(ink.a, 128);
    expect(border.b, 70);
    expect(border.a, 128);
  });

  test('every registered text module is owned by toolkit text rendering', () {
    for (final name in availableModules) {
      if (name == 'group/* (dynamic)') continue;
      final module = createModule(name);
      expect(module, isNotNull, reason: 'registry entry $name');
      if (module == null || module.name == 'sni' || module.name == 'tray') {
        continue;
      }

      final wrapper = ModuleWidget(module);
      if (!module.showsGraphics) {
        expect(
          module.widget,
          isA<TextRuns>(),
          reason: '$name must render text through TextRuns',
        );
        expect(wrapper.children, hasLength(1));
      }
    }
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

class _WidgetModule extends BarModule {
  _WidgetModule(Widget initial) {
    widget = initial;
  }

  @override
  String get name => 'widget-test';

  @override
  double draw(Painter painter, double x, double y) => 0;
}
