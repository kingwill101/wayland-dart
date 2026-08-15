import 'package:bardash/src/tray_menu_widget.dart';
import 'package:test/test.dart';
import 'package:window_toolkit/window_toolkit.dart';

void main() {
  setUp(StyleContext.reset);

  test('tray menu builds toolkit rows and keeps them inside the panel', () {
    final menu = TrayMenuWidget(
      entries: const [
        TrayMenuItemData(id: 1, label: 'Open'),
        TrayMenuItemData(id: 2, label: '', separator: true),
        TrayMenuItemData(id: 3, label: 'Disabled', enabled: false),
      ],
    );
    final painter = RecordingPainter(width: 420, height: 200);

    menu.measure(painter);
    menu.performLayout(menu.width);

    expect(menu.styleId, 'tray-menu');
    expect(menu.children, hasLength(3));
    expect(menu.children[0], isA<MenuItem>());
    expect(menu.children[1], isA<Separator>());
    expect(menu.children[2], isA<MenuItem>());
    for (final child in menu.children) {
      expect(child.x, greaterThanOrEqualTo(menu.x));
      expect(child.x + child.width, lessThanOrEqualTo(menu.width));
      expect(child.y + child.height, lessThanOrEqualTo(menu.height));
    }
    expect((menu.children[2] as MenuItem).enabled, isFalse);
    expect(menu.preferredWidth, inInclusiveRange(160, 420));
  });

  test('tray menu rows use shared hover and click routing', () {
    var activated = 0;
    final menu = TrayMenuWidget(
      entries: const [TrayMenuItemData(id: 7, label: 'Launch')],
      onTriggered: (id) => activated = id,
    );
    final host = WidgetHostController(menu);
    host.layoutRoot(menu.preferredWidth, menu.preferredHeight);
    final item = menu.menuItems.single;
    final x = item.x + 4;
    final y = item.y + 4;

    expect(host.updateHover(x, y), isTrue);
    expect(item.isHovered, isTrue);
    expect(item.hasPseudoClass('hover'), isTrue);
    expect(host.dispatchMouseDown(x, y, 0x110), isTrue);
    expect(host.dispatchMouseUp(x, y, 0x110), isTrue);
    expect(activated, 7);
  });

  test('tray menu rows accept CSS colors and hover rules', () {
    final provider = CssProvider()
      ..loadFromData(
        '#tray-menu { background-color: #101820; } '
        '#tray-menu-item:hover { background-color: #334455; }',
      );
    StyleContext.addProviderForScreen(provider);
    final menu = TrayMenuWidget(
      entries: const [TrayMenuItemData(id: 1, label: 'Open')],
    );
    final painter = RecordingPainter(width: 420, height: 200);
    menu.measure(painter);
    menu.performLayout(menu.width);
    final item = menu.menuItems.single;
    item.setInteractionState(WidgetState.hovered, true);

    final panelColor = menu.resolvedStyle().backgroundColor!;
    final itemColor = item.resolvedStyle().backgroundColor!;
    expect((panelColor.r, panelColor.g, panelColor.b), (16, 24, 32));
    expect((itemColor.r, itemColor.g, itemColor.b), (51, 68, 85));
  });
}
