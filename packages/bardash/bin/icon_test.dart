import 'package:window_toolkit/window_toolkit.dart';
import 'dart:io';
void main(){
  // simulate SNI icon lookup
  final dirs = ['/usr/share/icons/Papirus-Dark/22x22/apps','/usr/share/icons/Papirus-Dark/24x24/apps'];
  print(File('/usr/share/icons/Papirus-Dark/22x22/apps/blueman.png').existsSync());
  print(File('/usr/share/icons/Papirus-Dark/24x24/panel/blueman-tray.png').existsSync());
  print(File('/usr/share/icons/hicolor/22x22/apps/bluetooth.png').existsSync());
}
