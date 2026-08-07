import 'package:window_toolkit/window_toolkit.dart';
void main() {
  FontDatabase.instance.useSkiaEngine();
  print(FontDatabase.instance.families().where((n) => n.toLowerCase().contains('hack')).toList());
}
