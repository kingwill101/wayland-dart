// ignore_for_file: avoid_relative_lib_imports

import 'package:window_toolkit/window_toolkit.dart';

import '../lib/unicode_examples.dart';
import '../lib/widget_demo_window.dart';

class UnicodeExampleWindow extends WidgetDemoWindow {
  UnicodeExampleWindow() : super(buildUnicodeExample());
}

Future<void> main() async {
  await UnicodeExampleWindow().show();
  Application.instance.exec();
}
