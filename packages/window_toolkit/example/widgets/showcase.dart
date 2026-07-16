// ignore_for_file: avoid_relative_lib_imports
import 'package:layout_engine/layout_engine.dart' hide Offset;
import 'package:window_toolkit/window_toolkit.dart';
import '../lib/compound_examples.dart';
import '../lib/controls_examples.dart';
import '../lib/counter_example.dart';
import '../lib/flex_examples.dart';
import '../lib/layout_examples.dart';
import '../lib/more_controls_examples.dart';

/// Root stateful widget for the showcase.
/// WidgetWindow detects StatefulWidget and wraps it in an ElementTree.
class ShowcaseRoot extends StatefulWidget {
  @override
  State createState() => ShowcaseState();
}

class ShowcaseState extends State<ShowcaseRoot> {
  bool _showSecond = false;
  Color _boxColor = const Color(60, 60, 70);
  int _boxRadius = 0;

  @override
  ElementWidget build(BuildContext context) {
    return _buildLayout();
  }

  Widget _buildLayout() {
    final content = _buildScrollContent();
    content.x = 10;
    content.y = 118;
    content.performLayout(400);

    return SizedBox(width: 600, height: 800, child: content);
  }

  Widget _buildScrollContent() {
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
  Label _statusLabel;
  final ViewportScrollController _scrollCtrl = ViewportScrollController();
  final Scrollbar _scrollbar;

  Showcase()
      : _statusLabel = Label(''),
        _scrollbar = Scrollbar(controller: ViewportScrollController(), thickness: 6),
        super(ShowcaseRoot()) {
    contextMenu = ContextMenu(
      items: [
        MenuItem('Toggle Dark/Light Theme', onTriggered: toggleTheme),
        MenuItem('Say Hello', onTriggered: () {
          _statusLabel.text = 'Hello from window_toolkit!';
          paint();
        }),
        MenuItem('Reset Scroll', onTriggered: () {
          _scrollCtrl.jumpTo(0);
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
  void onMouseWheel(MouseWheelEvent event) {
    _scrollCtrl.scrollBy(event.dy.round());
    paint();
  }

  @override
  void draw(Painter painter) {
    super.draw(painter);

    // Scrollbar
    final contentH = height - 174;
    _scrollCtrl.updateMetrics(
      viewportExtent: contentH,
      contentExtent: 1200,
    );
    _scrollbar
      ..controller = _scrollCtrl
      ..viewportHeight = contentH
      ..x = width - 16
      ..y = 118
      ..width = 6
      ..draw(painter);

    // Status bar
    _statusLabel
      ..x = 10
      ..y = height - 24
      ..draw(painter);

    // Theme
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
