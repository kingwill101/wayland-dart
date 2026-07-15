// ignore_for_file: avoid_relative_lib_imports

import 'package:window_toolkit/window_toolkit.dart';

import '../lib/more_controls_examples.dart';
import '../lib/widget_demo_window.dart';

class SwitchExampleWindow extends WidgetDemoWindow {
  SwitchExampleWindow() : super(buildSwitchExample());
}

Future<void> main() async {
  await SwitchExampleWindow().show();
  Application.instance.exec();
}
