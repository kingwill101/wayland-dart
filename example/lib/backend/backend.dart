import 'package:example/event_loop.dart';
import 'package:example/mixins/event.dart';
import 'package:example/mixins/painter.dart';
import 'package:example/mixins/size.dart';

class Backend with Size, Painter {
  String title = '';

  Backend([int width = 800, int height = 600]) {
    setDimensions(width, height);
  }

  setTitle(String title) {}

  void pushEvent(Event event) {
    dispatch(event);
  }
}
