// ignore_for_file: avoid_relative_lib_imports
import 'package:layout_engine/layout_engine.dart' show ViewportScrollController;
import 'package:window_toolkit/window_toolkit.dart';
import '../lib/compound_examples.dart';
import '../lib/controls_examples.dart';
import '../lib/flex_examples.dart';
import '../lib/layout_examples.dart';
import '../lib/more_controls_examples.dart';

class Showcase extends WidgetWindow {
  bool _darkMode = true;
  bool _showSecond = false;
  Color _boxColor = const Color(60, 60, 70);
  int _boxRadius = 0;

  // Persistent animated widgets — created once, not per frame.
  final AnimatedContainer _animBox;
  final AnimatedCrossFade _crossFade;
  final Label _statusLabel;
  final ViewportScrollController _scrollCtrl = ViewportScrollController();
  final Scrollbar _scrollbar;
  final Widget _scrollContent;
  final Label _themeLabel;
  final Label _hint;

  Showcase()
      : _animBox = AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          child: Center(child: Label('Right-click menu → Animate: Color')),
        ),
        _crossFade = AnimatedCrossFade(
          firstChild: Padding(all: 4, child: Label('First child — right-click toggle')),
          secondChild: Padding(
            all: 4,
            child: HBox(spacing: 8, children: [
              Button('Fade'),
              Label('Second child'),
            ]),
          ),
          duration: const Duration(milliseconds: 200),
        ),
        _statusLabel = Label(''),
        _scrollbar = Scrollbar(controller: ViewportScrollController(), viewportHeight: 200, thickness: 6),
        _scrollContent = _buildScrollContent(),
        _themeLabel = Label(''),
        _hint = Label('Right-click for animated demos'),
        super(ScrollArea(child: SizedBox(width: 600, height: 600, child: Label('')))) {
    contextMenu = ContextMenu(
      items: [
        MenuItem('Toggle Dark/Light Theme', onTriggered: toggleTheme),
        MenuItem('Animate: Cross-Fade', onTriggered: () {
          _showSecond = !_showSecond;
          _crossFade.showFirst = !_showSecond;
          _statusLabel.text = _showSecond ? 'Showing second child' : 'Showing first child';
          paint();
        }),
        MenuItem('Animate: Color', onTriggered: () {
          _boxColor = _boxColor.r == 60
              ? const Color(0, 120, 255)
              : const Color(60, 60, 70);
          // Rebuild animated container with new color
          _rebuildAnimBox();
          _statusLabel.text = _boxColor.r == 60 ? 'Blue!' : 'Grey';
          paint();
        }),
        MenuItem('Animate: Border Radius', onTriggered: () {
          _boxRadius = _boxRadius == 0 ? 12 : 0;
          _rebuildAnimBox();
          _statusLabel.text = _boxRadius > 0 ? 'Rounded corners' : 'Sharp corners';
          paint();
        }),
        MenuItem('Reset Scroll', onTriggered: () {
          _scrollCtrl.jumpTo(0);
          _statusLabel.text = 'Scroll reset';
          paint();
        }),
        MenuItem('Say Hello', onTriggered: () {
          _statusLabel.text = 'Hello from window_toolkit!';
          paint();
        }),
      ],
    );
    _rebuildAnimBox();
    Widget.onNeedsRepaint = requestRedraw;
  }

  void _rebuildAnimBox() {
    _animBox.color = _boxColor;
    _animBox.borderRadius = _boxRadius.toDouble();
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

    // Animated container at top
    _animBox
      ..x = 10
      ..y = 8
      ..boxWidth = width - 20
      ..boxHeight = 48
      ..performLayout(width)
      ..draw(painter);

    // Cross-fade
    _crossFade
      ..x = 10
      ..y = 64
      ..width = width - 20
      ..performLayout(width)
      ..draw(painter);

    // Scrollable content
    final contentY = 118;
    final contentH = height - contentY - 56;

    _scrollContent
      ..x = 10
      ..y = contentY
      ..performLayout(width - 30);
    // Position children manually (VBoxLayout needs explicit layout call).
    // VBox.layout() handles child positioning internally.

    painter.save();
    painter.clipRect(Rect.fromLTWH(
      10, contentY.toDouble(), (width - 30).toDouble(), contentH.toDouble(),
    ));
    painter.translate(0, -_scrollCtrl.offset.toDouble());
    _scrollContent.draw(painter);
    painter.restore();

    // Scrollbar
    _scrollCtrl.updateMetrics(
      viewportExtent: contentH,
      contentExtent: _scrollContent.height,
    );
    _scrollbar
      ..controller = _scrollCtrl
      ..viewportHeight = contentH
      ..x = width - 16
      ..y = contentY
      ..width = 6
      ..draw(painter);

    // Status bar
    _statusLabel
      ..x = 10
      ..y = height - 24
      ..draw(painter);

    // Theme + hint
    _themeLabel
      ..text = _darkMode ? '🌙 Dark' : '☀️ Light'
      ..x = width - 80
      ..y = height - 24
      ..draw(painter);

    _hint
      ..x = 10
      ..y = height - 40
      ..draw(painter);
  }

  static Widget _buildScrollContent() {
    // Use VBox (layout-engine backed) for reliable child positioning.
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

        Label('— Menus & Dialogs —'),
        Padding(all: 8, child: buildMenuExample()),
        Padding(all: 8, child: buildTabExample()),
        Padding(all: 8, child: buildTooltipExample()),

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

Future<void> main() async {
  final w = Showcase();
  await w.show();
  Application.instance.exec();
}
