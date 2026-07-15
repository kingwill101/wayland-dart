// ignore_for_file: avoid_relative_lib_imports

import 'package:window_toolkit/window_toolkit.dart';

import '../lib/layout_examples.dart';
import '../lib/widget_demo_window.dart';

class WrapExampleWindow extends WidgetDemoWindow {
  WrapExampleWindow() : super(buildWrapExample());
}

Future<void> main() async {
  await WrapExampleWindow().show();
  Application.instance.exec();
}
