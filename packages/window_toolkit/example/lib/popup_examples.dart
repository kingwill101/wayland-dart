import 'package:window_toolkit/window_toolkit.dart';

/// Builder for a context menu widget tree (used inside PopupHost).
Widget buildContextMenuContent() {
  return VBoxLayout(
    spacing: 0,
    children: [
      MenuItem('Cut', onTriggered: () {}),
      MenuItem('Copy', onTriggered: () {}),
      MenuItem('Paste', onTriggered: () {}),
    ],
  )..width=120;
}

/// Builder for a dropdown popup widget tree.
Widget buildDropdownContent() {
  return VBoxLayout(
    spacing: 0,
    children: [
      MenuItem('Option A', onTriggered: () {}),
      MenuItem('Option B', onTriggered: () {}),
      MenuItem('Option C', onTriggered: () {}),
    ],
  )..width=140;
}
