import 'package:window_toolkit/window_toolkit.dart';

Widget buildScrollAreaExample() {
  final content = VBoxLayout(
    spacing: 4,
    children: [
      for (var i = 1; i <= 20; i++) Label('Line $i — scrolling content'),
    ],
  );
  content.width = 320;
  final scroll = ScrollArea(child: content);
  scroll.width = 320;
  scroll.height = 120;
  final card = Card(
    title: 'ScrollArea',
    children: [scroll],
  );
  card.width = 360;
  card.height = 200;
  return Padding(all: 24, child: card);
}

Widget buildTextFieldExample() {
  return Padding(
    all: 24,
    child: VBoxLayout(
      spacing: 16,
      children: [
        TextField(controller: TextEditingController(text: 'Hello'), placeholder: 'Type here'),
        TextField(placeholder: 'Password', obscured: true),
        TextField(controller: TextEditingController(text: 'Cursor at end..')),
      ],
    ),
  );
}

Widget buildDropdownExample() {
  return Padding(
    all: 24,
    child: Dropdown(
      items: ['Option A', 'Option B', 'Option C', 'Option D'],
      selectedIndex: 0,
    ),
  );
}

Widget buildListBoxExample() {
  return Padding(
    all: 24,
    child: ListBox(
      items: ['Red', 'Green', 'Blue', 'Yellow', 'Purple', 'Orange', 'Cyan'],
      selectedIndex: 0,
    )..width=160..height=150,
  );
}

Widget buildMenuExample() {
  return Padding(
    all: 24,
    child: VBoxLayout(
      spacing: 8,
      children: [
        MenuItem('Open File', onTriggered: () {}),
        MenuItem('Save'),
        MenuItem('Export As...'),
      ],
    )..width=160,
  );
}

Widget buildDialogExample() {
  return Padding(
    all: 24,
    child: Dialog(
      title: 'Confirm',
      message: 'Save changes before closing?',
      buttons: [
        DialogButton('Cancel'),
        DialogButton('Save'),
        DialogButton("Don't Save"),
      ],
    ),
  );
}

Widget buildTabExample() {
  final tabs = TabBar(
    labels: ['Notes', 'Preview', 'Info'],
    activeIndex: 0,
  );
  tabs.width = 360;
  tabs.height = 28;
  final card = Card(
    title: 'TabBar',
    children: [tabs],
  );
  card.width = 400;
  card.height = 80;
  return Padding(all: 24, child: card);
}

Widget buildTooltipExample() {
  return Padding(
    all: 24,
    child: Tooltip(
      text: 'Click to submit',
      child: Button('Submit'),
      visible: true,
    ),
  );
}
