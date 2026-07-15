// ignore_for_file: avoid_relative_lib_imports

import 'package:window_toolkit/window_toolkit.dart';

import '../lib/controls_examples.dart';
import '../lib/widget_demo_window.dart';

class CheckboxExampleWindow extends WidgetDemoWindow {
  CheckboxExampleWindow() : super(buildCheckboxExample());
}

Future<void> main() async {
  await CheckboxExampleWindow().show();
  Application.instance.exec();
}
