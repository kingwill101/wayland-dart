// ignore_for_file: avoid_relative_lib_imports
import 'package:window_toolkit/window_toolkit.dart';
import '../lib/popup_examples.dart';

/// Demonstrates using PopupHost for real xdg-popup surfaces.
///
/// In a live Wayland session, right-click opens a real xdg-popup
/// via [PopupHost.show] with the content from [buildContextMenuContent].
/// Without Wayland the context menu falls back to in-window rendering.
class PopupDemoWindow extends WidgetWindow {
  PopupDemoWindow() : super(_buildContent()) {
    contextMenu = ContextMenu(
      items: [
        MenuItem('Popup option 1', onTriggered: () {}),
        MenuItem('Popup option 2', onTriggered: () {}),
      ],
    );
  }

  static Widget _buildContent() {
    return Padding(
      all: 24,
      child: VBoxLayout(
        spacing: 16,
        children: [
          Label('Right-click anywhere to open context menu.'),
          Label('With a Wayland compositor, the menu opens as'),
          Label('a real xdg-popup surface via PopupHost.'),
          Label(''),
          Label('Shared popup content builders:'),
          Padding(all: 4, child: buildContextMenuContent()),
        ],
      ),
    );
  }
}

Future<void> main() async {
  final w = PopupDemoWindow();
  await w.show();
  Application.instance.exec();
}
