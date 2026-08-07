// ignore_for_file: avoid_relative_lib_imports
import 'package:window_toolkit/window_toolkit.dart';
import '../lib/compound_examples.dart';
import '../lib/controls_examples.dart';
import '../lib/counter_example.dart';
import '../lib/flex_examples.dart';
import '../lib/layout_examples.dart';
import '../lib/more_controls_examples.dart';

/// Root stateful widget for the showcase.
class ShowcaseRoot extends StatefulWidget {
  @override
  State createState() => ShowcaseState();
}

class ShowcaseState extends State<ShowcaseRoot> {

  @override
  ElementWidget build(BuildContext context) {
    return ScrollArea(child: _buildContent(), showVertical: true);
  }

  Widget _buildContent() {
    return VBox(
      spacing: 6,
      children: [
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

        Label('— StatefulWidget —'),
        ElementHost(child: CounterWidget(label: 'Stateful Counter')),

        Label('— Animation —'),
        AnimatedSlide(
          delta: const Offset(0, 5),
          duration: const Duration(milliseconds: 300),
          child: Padding(
            all: 4,
            child: AnimatedOpacity(
              opacity: 0.8,
              duration: const Duration(milliseconds: 200),
              child: Label('AnimatedOpacity + AnimatedSlide demo'),
            ),
          ),
        ),

        Label('— Dialogs —'),
        Padding(all: 8, child: buildDialogExample()),
        Padding(all: 8, child: buildCardExample()),
      ],
    );
  }
}

class Showcase extends WidgetWindow {
  bool _darkMode = true;
  final Label _statusLabel;

  Showcase()
      : _statusLabel = Label(''),
        super(ShowcaseRoot()) {
    contextMenu = ContextMenu(
      items: [
        MenuItem('Toggle Dark/Light Theme', onTriggered: toggleTheme),
        MenuItem('Say Hello', onTriggered: () {
          _statusLabel.text = 'Hello from window_toolkit!';
          paint();
        }),
      ],
    );
    Widget.onNeedsRepaint = requestRedraw;
  }

  void toggleTheme() {
    _darkMode = !_darkMode;
    Palette.current = _darkMode ? Palette.darkPalette : Palette.lightPalette;
    _statusLabel.text = _darkMode ? 'Light theme' : 'Dark theme';
    paint();
  }

  @override
  void draw(Painter painter) {
    super.draw(painter);

    // Status bar
    _statusLabel
      ..x = 10
      ..y = height - 24
      ..draw(painter);

    // Theme indicator
    final themeLabel = Label(_darkMode ? '🌙 Dark' : '☀️ Light');
    themeLabel
      ..x = width - 80
      ..y = height - 24
      ..draw(painter);

    // Hint
    final hint = Label('Right-click for menu — scroll to explore');
    hint
      ..x = 10
      ..y = height - 40
      ..draw(painter);
  }
}

Future<void> main() async {
  final w = Showcase();
  await w.show();
  Application.instance.exec();
}
