import 'package:window_toolkit/window_toolkit.dart';
import 'package:test/test.dart';

void main() {
  group('Window toolkit', () {
    test('exports Application', () {
      expect(Application, isNotNull);
    });

    test('exports WaylandBackend', () {
      expect(WaylandBackend, isNotNull);
    });

    test('exports layout widgets', () {
      expect(HBox, isNotNull);
      expect(Align, isNotNull);
      expect(Padding, isNotNull);
    });

    test('exports control widgets', () {
      expect(Checkbox, isNotNull);
      expect(Slider, isNotNull);
      expect(Card, isNotNull);
      expect(Switch, isNotNull);
      expect(RadioButton, isNotNull);
      expect(IconButton, isNotNull);
      expect(WrapLayout, isNotNull);
      expect(Row, isNotNull);
      expect(Column, isNotNull);
      expect(Flex, isNotNull);
      expect(Expanded, isNotNull);
      expect(Flexible, isNotNull);
    });

    test('exports runtime widgets', () {
      expect(WidgetWindow, isNotNull);
    });

    test('exports advanced widgets', () {
      expect(ScrollArea, isNotNull);
      expect(TextField, isNotNull);
      expect(TabBar, isNotNull);
      expect(TabView, isNotNull);
      expect(Tooltip, isNotNull);
      expect(Dropdown, isNotNull);
      expect(ListBox, isNotNull);
      expect(Menu, isNotNull);
      expect(Dialog, isNotNull);
      expect(ToggleButton, isNotNull);
      expect(SegmentedControl, isNotNull);
      expect(RangeSlider, isNotNull);
      expect(Spinner, isNotNull);
      expect(Badge, isNotNull);
      expect(GroupBox, isNotNull);
      expect(ContextMenu, isNotNull);
      expect(TextEditingController, isNotNull);
    });
  });
}
