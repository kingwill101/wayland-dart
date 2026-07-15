// ignore_for_file: avoid_relative_lib_imports
import 'package:window_toolkit/window_toolkit.dart';
import '../lib/compound_examples.dart';
import '../lib/widget_demo_window.dart';

class ScrollAreaWindow extends WidgetDemoWindow {
  ScrollAreaWindow() : super(buildScrollAreaExample());
}
Future<void> main() async { await ScrollAreaWindow().show(); Application.instance.exec(); }
