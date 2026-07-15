import 'package:window_toolkit/window_toolkit.dart';

Widget buildHBoxExample() {
  return Padding(
    all: 24,
    child: HBox(
      spacing: 12,
      children: [
        Button('One'),
        Button('Two'),
        Button('Three'),
      ],
    ),
  );
}

Widget buildAlignExample() {
  return Padding(
    all: 24,
    child: Align(
      horizontalAlignment: HorizontalAlignment.right,
      verticalAlignment: VerticalAlignment.bottom,
      child: Button('Bottom Right'),
    ),
  );
}

Widget buildPaddingExample() {
  return Padding(
    all: 24,
    child: VBoxLayout(
      spacing: 12,
      children: [
        Button('Top'),
        Button('Bottom'),
      ],
    ),
  );
}

Widget buildWrapExample() {
  return Padding(
    all: 24,
    child: WrapLayout(
      spacing: 10,
      runSpacing: 10,
      children: [
        Button('Alpha'),
        Button('Beta'),
        Button('Gamma'),
        Button('Delta'),
        Button('Longer Button'),
        Button('Z'),
      ],
    ),
  );
}
