import 'package:window_toolkit/window_toolkit.dart';

Widget buildSwitchExample() {
  return Padding(
    all: 24,
    child: VBoxLayout(
      spacing: 16,
      children: [
        HBox(spacing: 12, children: [Switch(value: true), Label('Enabled')]),
        HBox(spacing: 12, children: [Switch(), Label('Disabled')]),
      ],
    ),
  );
}

Widget buildRadioExample() {
  final card = Card(
    title: 'Modes',
    children: [
      RadioButton('One', selected: true),
      RadioButton('Two'),
      RadioButton('Three'),
    ],
  );
  card.width = 240;
  card.height = 160;
  return Padding(all: 24, child: card);
}

Widget buildIconButtonExample() {
  return Padding(
    all: 24,
    child: HBox(
      spacing: 12,
      children: [
        IconButton(IconShape.circle),
        IconButton(IconShape.square),
        IconButton(IconShape.triangle),
      ],
    ),
  );
}
