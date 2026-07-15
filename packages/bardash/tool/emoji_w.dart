import 'package:window_toolkit/window_toolkit.dart';
void main() {
  FontDatabase.instance.useSkiaEngine();
  FontDatabase.instance.setRoleFamily(FontRole.icon, 'Noto Color Emoji');
  FontDatabase.instance.setRoleFamily(FontRole.ui, 'sans');
  for (final ch in ['🔊','🔉','🔈','🔇','🎤','🔋','🪫','⚡','100%','49%']) {
    final f = ch.runes.length <= 2 ? Font.icon(pixelSize: 13) : Font.ui(pixelSize: 13);
    final m = FontDatabase.instance.metrics(f);
    print('$ch advance=${m.horizontalAdvance(ch).toStringAsFixed(1)}');
  }
  // with Hack
  FontDatabase.instance.setRoleFamily(FontRole.icon, 'Hack Nerd Font');
  for (final ch in ['🔊','🔋','⚡']) {
    final m = FontDatabase.instance.metrics(Font.icon(pixelSize: 13));
    print('hack $ch advance=${m.horizontalAdvance(ch).toStringAsFixed(1)}');
  }
}
