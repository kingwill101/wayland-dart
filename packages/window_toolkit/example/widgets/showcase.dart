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
  Label _statusLabel;
  bool _showSecond = false;
  final ViewportScrollController _scrollCtrl = ViewportScrollController();
  Color _boxColor = const Color(60, 60, 70);
  int _boxRadius = 0;

  Showcase()
      : _statusLabel = Label('Interactive demo — right-click for animated demos'),
        super(ScrollArea(child: SizedBox(width: 600, height: 30, child: Label('Loading...')))) {
    _statusLabel.x = 10;
    _statusLabel.y = 100;

    contextMenu = ContextMenu(
      items: [
        MenuItem('Toggle Dark/Light Theme', onTriggered: toggleTheme),
        MenuItem('Animate: Cross-Fade', onTriggered: () {
          _showSecond = !_showSecond;
          _statusLabel.text = _showSecond ? 'Showing second child' : 'Showing first child';
          paint();
        }),
        MenuItem('Animate: Color', onTriggered: () {
          _boxColor = _boxColor.r == 60
              ? const Color(0, 120, 255)
              : const Color(60, 60, 70);
          paint();
        }),
        MenuItem('Animate: Border Radius', onTriggered: () {
          _boxRadius = _boxRadius == 0 ? 12 : 0;
          _statusLabel.text = _boxRadius > 0 ? 'Rounded corners' : 'Sharp corners';
          paint();
        }),
        MenuItem('Reset Scroll', onTriggered: () {
          _scrollCtrl.jumpTo(0);
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

    // Animated container demo at the top
    AnimatedContainer(
      color: _boxColor,
      boxWidth: width - 20,
      boxHeight: 50,
      borderRadius: _boxRadius.toDouble(),
      duration: const Duration(milliseconds: 300),
      child: Center(
        child: Label(_boxColor.r == 60 ? 'Right-click → Animate: Color' : 'Blue!'),
      ),
    )
      ..x = 10
      ..y = 10
      ..performLayout(width)
      ..draw(painter);

    // Cross-fade demo
    AnimatedCrossFade(
      firstChild: Padding(all: 4, child: Label('First child — right-click toggle')),
      secondChild: Padding(
        all: 4,
        child: HBox(spacing: 8, children: [
          Button('Fade'),
          Label('Second child'),
        ]),
      ),
      showFirst: !_showSecond,
      duration: const Duration(milliseconds: 200),
    )
      ..x = 10
      ..y = 70
      ..performLayout(width)
      ..draw(painter);

    // Scrollable content area with proper scrollbar
    final contentY = 120;
    final contentH = height - contentY - 60;
    final scrollContent = _buildScrollContent();
    scrollContent
      ..x = 10
      ..y = contentY
      ..performLayout(width - 30);

    // Clip to viewport
    painter.save();
    painter.clipRect(Rect.fromLTWH(
      10, contentY.toDouble(), (width - 30).toDouble(), contentH.toDouble(),
    ));
    painter.translate(0, -_scrollCtrl.offset.toDouble());
    scrollContent.draw(painter);
    painter.restore();

    // Scrollbar
    _scrollCtrl.updateMetrics(
      viewportExtent: contentH,
      contentExtent: scrollContent.height,
    );
    Scrollbar(
      controller: _scrollCtrl,
      viewportHeight: contentH,
      thickness: 6,
    )
      ..x = width - 16
      ..y = contentY
      ..width = 6
      ..draw(painter);

    // Status bar
    _statusLabel.x = 10;
    _statusLabel.y = height - 24;
    _statusLabel.draw(painter);

    // Theme indicator
    final themeLabel = Label(_darkMode ? '🌙 Dark' : '☀️ Light');
    themeLabel.x = width - 80;
    themeLabel.y = height - 24;
    themeLabel.draw(painter);

    // Right-click hint
    final hint = Label('Right-click for animated demos');
    hint.x = 10;
    hint.y = height - 40;
    hint.draw(painter);
  }

  Widget _buildScrollContent() {
    return VBoxLayout(
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
