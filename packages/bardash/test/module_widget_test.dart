import 'package:test/test.dart';
import 'package:window_toolkit/window_toolkit.dart';
import 'package:bardash/src/module_widget.dart';
import 'package:bardash/src/metrics.dart';
import 'package:bardash/src/modules/module.dart';

class FakeModule extends BarModule {
  @override String get name => 'fake';
  @override double draw(Painter p, double x, double y) {
    p.drawText(output, Offset(x,y), color: const Color(255,0,0));
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
    final m = FakeModule()..output='hi';
    final w = ModuleWidget(m);
    expect(w.styleId, 'fake');
    expect(w.hasClass('module'), isTrue);
    expect(w.hasClass('fake'), isTrue);
  });
  test('ModuleWidget background from CSS', () {
    final provider = CssProvider()..loadFromData('#fake { background-color: #ff0000; }');
    StyleContext.addProviderForScreen(provider);
    final m = FakeModule()..output='hi'..paddingLeft=2..paddingRight=2;
    final w = ModuleWidget(m)..x=0..y=0..width=100..height=30;
    final p = RecordingPainter(width: 100, height: 30);
    w.draw(p);
    final bg = p.commands.whereType<DrawRectCommand>().first;
    expect(bg.paint.color.r, 255);
  });
  test('ModuleWidget hover pseudo', () {
    final provider = CssProvider()..loadFromData('#fake:hover { background-color: #00ff00; }');
    StyleContext.addProviderForScreen(provider);
    final m = FakeModule()..output='hi';
    final w = ModuleWidget(m)..x=0..y=0..width=100..height=30;
    w.addPseudoClass('hover');
    final ctx = StyleContext.forWidget(w);
    expect(ctx.parsedBackgroundColor?.g, 255);
  });
  test('ModuleWidget text color from CSS', () {
    final provider = CssProvider()..loadFromData('#fake { color: #0000ff; }');
    StyleContext.addProviderForScreen(provider);
    final m = FakeModule()..output='hi';
    final w = ModuleWidget(m)..x=0..y=0..width=100..height=30;
    final p = RecordingPainter(width: 100, height: 30);
    w.draw(p);
    final txt = p.commands.whereType<DrawTextCommand>().first;
    expect(txt.color?.b, 255);
  });
}
