import 'package:window_toolkit/window_toolkit.dart';

void main() {
  final db = FontDatabase.instance;
  db.useSkiaEngine();
  db.setRoleFamily(FontRole.ui, 'Noto Sans');
  db.setRoleFamily(FontRole.icon, 'Hack Nerd Font');
  final m = db.metrics(const Font.ui(pixelSize: 13));
  print('engine=${db.engineId}');
  print('Apps advance=${m.horizontalAdvance('Apps')}');
  print('ascent=${m.ascent} descent=${m.descent} height=${m.height}');
  final icon = db.metrics(const Font.icon(pixelSize: 13));
  print('gear advance=${icon.horizontalAdvance('\uf013')}');
}
