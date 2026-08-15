import 'package:test/test.dart';
import 'package:window_toolkit/window_toolkit.dart';
import 'package:window_toolkit/src/painter/skia_text_engine.dart';

void main() {
  tearDown(FontDatabase.instance.useBitmapEngine);

  test('Skia text metrics shape a family stack with private-use text', () {
    final database = FontDatabase.instance;
    database.useSkiaEngine();

    final metrics = database.metrics(
      const Font(
        family: 'A family that is not installed, sans-serif',
        pixelSize: 16,
      ),
    );

    expect(metrics.horizontalAdvance('󰖩 100%'), greaterThan(0));
    expect(metrics.boundingRect('󰖩 100%').height, greaterThan(0));
  });

  test('private-use icon runs use the resolved glyph bounds', () {
    final database = FontDatabase.instance;
    database.useSkiaEngine();
    final hack = database.families().where(
      (family) => family.toLowerCase() == 'hack nerd font',
    );
    if (hack.isEmpty) return;

    final bounds = SkiaTextEngine.shared.measureTextBounds(
      '\uf011',
      size: 13,
      fontFamily: hack.first,
    );

    // A shaped fallback tofu run used to report a negative top and render a
    // square on both raster and Dawn/Graphite painters. Direct icon blobs are
    // normalized to the same line-top origin as ordinary toolkit text.
    expect(bounds.top, closeTo(0, 0.001));
    expect(bounds.height, greaterThan(0));
  });
}
