// ignore_for_file: avoid_relative_lib_imports

import 'package:window_toolkit/window_toolkit.dart';

import '../lib/controls_examples.dart';
import '../lib/widget_demo_window.dart';

class CardExampleWindow extends WidgetDemoWindow {
  CardExampleWindow() : super(buildCardExample());
}

Future<void> main() async {
  await CardExampleWindow().show();
  Application.instance.exec();
}
