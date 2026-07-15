// ignore_for_file: avoid_relative_lib_imports
import 'package:window_toolkit/window_toolkit.dart';
import '../lib/compound_examples.dart';
import '../lib/controls_examples.dart';
import '../lib/flex_examples.dart';
import '../lib/layout_examples.dart';
import '../lib/more_controls_examples.dart';

class Showcase extends WidgetWindow {
  bool _darkMode = true;
  Label _statusLabel;

  Showcase()
      : _statusLabel = Label('Interactive demo — click widgets to interact'),
        super(_buildShowcase(Palette.current == Palette.darkPalette)) {
    _statusLabel.x = 10;
    _statusLabel.y = 100;

    contextMenu = ContextMenu(
      items: [
        MenuItem('Toggle Dark/Light Theme', onTriggered: toggleTheme),
        MenuItem('Reset Scroll', onTriggered: () {
          if (root is ScrollArea) (root as ScrollArea).scrollY = 0;
          _statusLabel.text = 'Scroll reset';
        }),
        MenuItem('Say Hello', onTriggered: () {
          _statusLabel.text = 'Hello from window_toolkit!';
        }),
      ],
    );
  }

  void toggleTheme() {
    _darkMode = !_darkMode;
    Palette.current = _darkMode ? Palette.darkPalette : Palette.lightPalette;
    _statusLabel.text = _darkMode ? 'Dark theme' : 'Light theme';
    paint();
  }

  @override
  void draw(Painter painter) {
    super.draw(painter);
    // Draw a small status bar at the bottom
    _statusLabel.x = 10;
    _statusLabel.y = height - 24;
    _statusLabel.draw(painter);

    // Draw theme indicator
    final themeLabel = Label(_darkMode ? '🌙 Dark' : '☀️ Light');
    themeLabel.x = width - 80;
    themeLabel.y = height - 24;
    themeLabel.draw(painter);

    // Right-click hint
    final hint = Label('Right-click for menu');
    hint.x = 10;
    hint.y = height - 40;
    hint.draw(painter);
  }

  static Widget _buildShowcase(bool isDark) {
    final sections = VBoxLayout(
      spacing: 8,
      children: [
        Label('Right-click for context menu — scroll to explore'),
        Label('— Layouts —'),
        Padding(all: 8, child: buildHBoxExample()),
        Padding(all: 8, child: buildRowExample()),
        Padding(all: 8, child: buildColumnExample()),
        Padding(all: 8, child: buildWrapExample()),
        Padding(all: 8, child: buildPaddingExample()),
        Padding(all: 8, child: buildAlignExample()),

        Label('— Controls —'),
        Padding(all: 8, child: buildCheckboxExample()),
        Padding(all: 8, child: buildSliderExample()),
        Padding(all: 8, child: buildSwitchExample()),
        Padding(all: 8, child: buildDropdownExample()),
        Padding(all: 8, child: buildIconButtonExample()),
        Padding(all: 8, child: buildRadioExample()),

        Label('— Text —'),
        Padding(all: 8, child: buildTextFieldExample()),

        Label('— Scrolling —'),
        Padding(all: 8, child: buildScrollAreaExample()),

        Label('— Menus & Dialogs —'),
        Padding(all: 8, child: buildMenuExample()),
        Padding(all: 8, child: buildTabExample()),
        Padding(all: 8, child: buildTooltipExample()),

        Label('— Dialogs —'),
        Padding(all: 8, child: buildDialogExample()),
        Padding(all: 8, child: buildCardExample()),
      ],
    );
    sections.width = 600;

    final scroll = ScrollArea(child: sections);
    scroll.width = 620;
    return scroll;
  }
}

Future<void> main() async {
  final w = Showcase();
  await w.show();
  Application.instance.exec();
}
