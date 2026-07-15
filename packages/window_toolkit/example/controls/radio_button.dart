// ignore_for_file: avoid_relative_lib_imports

import 'package:window_toolkit/window_toolkit.dart';

import '../lib/more_controls_examples.dart';
import '../lib/widget_demo_window.dart';

class RadioButtonExampleWindow extends WidgetDemoWindow {
  RadioButtonExampleWindow() : super(buildRadioExample());
}

Future<void> main() async {
  await RadioButtonExampleWindow().show();
  Application.instance.exec();
}
