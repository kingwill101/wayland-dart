import 'package:window_toolkit/window_toolkit.dart';

Widget buildCheckboxExample() {
  final checked = Checkbox(checked: true);
  final unchecked = Checkbox();
  final label1 = Label('Checked');
  final label2 = Label('Unchecked');

  return Padding(
    all: 24,
    child: VBoxLayout(
      spacing: 16,
      children: [
        HBox(spacing: 12, children: [checked, label1]),
        HBox(spacing: 12, children: [unchecked, label2]),
      ],
    ),
  );
}

Widget buildSliderExample() {
  return Padding(
    all: 24,
    child: VBoxLayout(
      spacing: 24,
      children: [
        Slider(value: 20),
        Slider(value: 50),
        Slider(value: 80),
      ],
    ),
  );
}

Widget buildCardExample() {
  final card = Card(
    title: 'Controls',
    children: [
      Checkbox(checked: true),
      Slider(value: 40),
    ],
  );
  card.width = 260;
  card.height = 180;
  return Padding(
    all: 24,
    child: card,
  );
}
