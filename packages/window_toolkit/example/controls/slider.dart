// ignore_for_file: avoid_relative_lib_imports

import 'package:window_toolkit/window_toolkit.dart';

import '../lib/controls_examples.dart';
import '../lib/widget_demo_window.dart';

class SliderExampleWindow extends WidgetDemoWindow {
  SliderExampleWindow() : super(buildSliderExample());
}

Future<void> main() async {
  await SliderExampleWindow().show();
  Application.instance.exec();
}
