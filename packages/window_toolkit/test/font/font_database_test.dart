import 'package:test/test.dart';
import 'package:window_toolkit/window_toolkit.dart';

void main() {
  late FontDatabase db;

  setUp(() {
    db = FontDatabase.instance;
    db.useBitmapEngine();
    db.setRoleFamily(FontRole.ui, 'sans');
    db.setRoleFamily(FontRole.icon, 'bitmap');
    db.setRoleFamily(FontRole.mono, 'monospace');
    db.defaultPixelSize = 13;
  });

  test('engine id is bitmap when forced', () {
    expect(db.engineId, 'bitmap');
  });

  test('role resolution maps to family', () {
    final f = db.resolveRequest(const Font.ui(pixelSize: 13));
    expect(f.family, 'sans');
    expect(f.pixelSize, 13);
  });

  test('horizontalAdvance is fixed cell for bitmap', () {
    final m = db.metrics(const Font(family: 'bitmap', pixelSize: 16));
    expect(m.horizontalAdvance('Apps'), 4 * 8); // 8px cell
    expect(m.fixedPitch, isTrue);
  });

  test('elidedText shortens long strings', () {
    final m = db.metrics(const Font(family: 'bitmap', pixelSize: 16));
    final elided = m.elidedText('HelloWorld', 8 * 6.0); // 6 cells
    expect(elided.endsWith('…'), isTrue);
    expect(m.horizontalAdvance(elided), lessThanOrEqualTo(8 * 6.0));
  });

  test('Font.ui / icon / mono constructors set roles', () {
    expect(const Font.ui().role, FontRole.ui);
    expect(const Font.icon().role, FontRole.icon);
    expect(const Font.mono().role, FontRole.mono);
  });

  test('families lists aliases', () {
    expect(db.families(), contains('bitmap'));
  });

  test('fontInfo reports fixed pitch for bitmap', () {
    final info = db.fontInfo(const Font(family: 'bitmap'));
    expect(info.fixedPitch, isTrue);
    expect(info.family, 'bitmap');
  });

  test('PainterFont extension advances via database', () {
    // RecordingPainter implements Painter; extension uses FontDatabase.
    final painter = RecordingPainter();
    final w = painter.measureTextFont('AB', const Font(family: 'bitmap'));
    // Bitmap is 8px/cell; RecordingPainter also has its own measure —
    // FontDatabase bitmap path is used by measureTextFont.
    expect(w, 16);
  });

  test('switching engines updates engineId', () {
    db.useBitmapEngine();
    expect(db.engineId, 'bitmap');
  });

  test('metrics are reused for an unchanged resolved font request', () {
    const font = Font(family: 'bitmap', pixelSize: 16);
    expect(identical(db.metrics(font), db.metrics(font)), isTrue);
  });
}
