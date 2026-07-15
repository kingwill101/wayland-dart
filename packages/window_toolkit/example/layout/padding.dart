// ignore_for_file: avoid_relative_lib_imports

import 'package:window_toolkit/window_toolkit.dart';

import '../lib/layout_examples.dart';
import '../lib/widget_demo_window.dart';

class PaddingExampleWindow extends WidgetDemoWindow {
  PaddingExampleWindow() : super(buildPaddingExample());
}

Future<void> main() async {
  await PaddingExampleWindow().show();
  Application.instance.exec();
}
