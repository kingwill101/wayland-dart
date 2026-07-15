import 'package:window_toolkit/window_toolkit.dart';

Widget buildRowExample() {
  return Padding(
    all: 24,
    child: Row(
      spacing: 12,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Button('Left'),
        Expanded(child: Button('Expanded center')),
        Button('Right'),
      ],
    ),
  );
}

Widget buildColumnExample() {
  return Padding(
    all: 24,
    child: Column(
      spacing: 12,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Button('Top'),
        Flexible(child: Label('Flexible label'), fit: FlexFit.loose),
        Expanded(child: Button('Bottom fills remaining space')),
      ],
    ),
  );
}

Widget buildFlexExample() {
  return Padding(
    all: 24,
    child: Column(
      spacing: 16,
      children: [
        Row(
          spacing: 8,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Button('A'),
            Button('B'),
            Button('C'),
          ],
        ),
        Row(
          spacing: 8,
          children: [
            Expanded(child: Button('Expanded')),
            Spacer(),
            Flexible(child: Button('Flexible'), fit: FlexFit.loose),
          ],
        ),
      ],
    ),
  );
}
