// ignore_for_file: avoid_relative_lib_imports

import 'package:window_toolkit/window_toolkit.dart';

import '../lib/layout_examples.dart';
import '../lib/widget_demo_window.dart';

class HBoxExampleWindow extends WidgetDemoWindow {
  HBoxExampleWindow() : super(buildHBoxExample());
}

Future<void> main() async {
  await HBoxExampleWindow().show();
  Application.instance.exec();
}
