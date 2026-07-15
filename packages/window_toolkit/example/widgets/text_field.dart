// ignore_for_file: avoid_relative_lib_imports
import 'package:window_toolkit/window_toolkit.dart';
import '../lib/compound_examples.dart';
import '../lib/widget_demo_window.dart';

class TextFieldWindow extends WidgetDemoWindow {
  TextFieldWindow() : super(buildTextFieldExample());
}
Future<void> main() async { await TextFieldWindow().show(); Application.instance.exec(); }
