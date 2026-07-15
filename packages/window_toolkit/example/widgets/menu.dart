// ignore_for_file: avoid_relative_lib_imports
import 'package:window_toolkit/window_toolkit.dart';
import '../lib/compound_examples.dart';
import '../lib/widget_demo_window.dart';

class MenuExampleWindow extends WidgetDemoWindow {
  MenuExampleWindow() : super(buildMenuExample());
}
Future<void> main() async { await MenuExampleWindow().show(); Application.instance.exec(); }
