import 'package:window_toolkit/window_toolkit.dart';
void main() {
  FontDatabase.instance.useSkiaEngine();
  FontDatabase.instance.setRoleFamily(FontRole.ui, 'sans');
  FontDatabase.instance.setRoleFamily(FontRole.icon, 'Hack Nerd Font');
  final icons = ['󰤯','󰤟','󰤢','󰤥','󰤨','󰖪','🔋','🪫','⚡',''];
  for (final ch in icons) {
    final ui = FontDatabase.instance.metrics(Font.ui(pixelSize: 13)).horizontalAdvance(ch);
    final ic = FontDatabase.instance.metrics(Font.icon(pixelSize: 14)).horizontalAdvance(ch);
    final em = FontDatabase.instance.metrics(Font(family: 'Noto Color Emoji', pixelSize: 13)).horizontalAdvance(ch);
    print('$ch ui=$ui icon=$ic emoji=$em');
  }
}
