import 'package:example/widget.dart';
import 'package:example/window/wayland.dart';

class Window extends Wayland {
  @override
  onKeyPressed(KeyEvent event) {
    if (event.key == 1) {
      shouldExit = true;
    }
  }
}
