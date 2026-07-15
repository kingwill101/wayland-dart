// ignore_for_file: avoid_relative_lib_imports

import 'package:window_toolkit/window_toolkit.dart';

import '../lib/flex_examples.dart';
import '../lib/widget_demo_window.dart';

class ColumnExampleWindow extends WidgetDemoWindow {
  ColumnExampleWindow() : super(buildColumnExample());
}

Future<void> main() async {
  await ColumnExampleWindow().show();
  Application.instance.exec();
}
