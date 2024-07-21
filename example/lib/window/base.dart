import 'package:example/mixins/size.dart';
import 'package:example/widget.dart';

import '../mixins/dispatcher.dart';
import '../mixins/painter.dart';

class BaseWindow extends BaseWidget with Size, Painter, Runner {
  String title = "";
  bool shouldExit = false;

  show() {
    while (!shouldExit) {
      dispatch();
    }
  }
}
