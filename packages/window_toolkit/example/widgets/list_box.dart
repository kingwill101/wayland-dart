// ignore_for_file: avoid_relative_lib_imports
import 'package:window_toolkit/window_toolkit.dart';
import '../lib/compound_examples.dart';
import '../lib/widget_demo_window.dart';

class ListBoxWindow extends WidgetDemoWindow {
  ListBoxWindow() : super(buildListBoxExample());
}
Future<void> main() async { await ListBoxWindow().show(); Application.instance.exec(); }
