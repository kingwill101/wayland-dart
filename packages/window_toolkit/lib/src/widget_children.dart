import 'widget.dart';
import 'widgets/align.dart';
import 'widgets/card.dart';
import 'widgets/center.dart';
import 'widgets/context_menu.dart';
import 'widgets/decorated_box.dart';
import 'widgets/dialog.dart';
import 'widgets/element_host.dart';
import 'widgets/flex.dart';
import 'widgets/frame.dart';
import 'widgets/group_box.dart';
import 'widgets/hbox.dart';
import 'widgets/layout.dart';
import 'widgets/list_view.dart';
import 'widgets/menu.dart';
import 'widgets/mouse_region.dart';
import 'widgets/padding.dart';
import 'widgets/scroll_area.dart';
import 'widgets/sized_box.dart';
import 'widgets/stack.dart';
import 'widgets/tabs.dart';
import 'widgets/tooltip.dart';
import 'widgets/vbox.dart';
import 'widgets/wrap.dart';

/// Returns the children of any known composite widget type.
///
/// Prefer each widget's own [Widget.children] override when non-empty; fall
/// back to type-specific knowledge for older composites that still store kids
/// only as fields.
///
/// Used by [Widget.dumpChildren] (tree dumps via layout_engine [TreeDump])
/// and by [WidgetWindow] for hit-testing when needed.
List<Widget> childrenOf(Widget w) {
  // 1. Prefer the virtual getter when the widget exposes children.
  final viaGetter = w.children;
  if (viaGetter.isNotEmpty) return viaGetter;

  // 2. Field-based composites that may not override [children].
  if (w is ScrollArea) return [w.child];
  if (w is Padding) return [w.child];
  if (w is Frame) return w.children;
  if (w is Card) return w.children;
  if (w is GroupBox) return w.children;
  if (w is Tooltip) return [w.child];
  if (w is Align) return [w.child];
  if (w is WrapLayout) return w.children;
  if (w is Center) return [w.child];
  if (w is SizedBox) {
    final c = w.child;
    if (c != null) return [c];
  }
  if (w is ConstrainedBox) return [w.child];
  if (w is DecoratedBox) {
    final c = w.child;
    if (c != null) return [c];
  }
  if (w is Stack) return w.children;
  if (w is MouseRegion) return [w.child];
  if (w is ListView) return w.listChildren;
  if (w is TabView) return w.pages;
  if (w is VBoxLayout) return w.children;
  if (w is Flex) return w.children;
  if (w is Flexible) return [w.child];
  if (w is HBox) return w.children;
  if (w is VBox) return w.children;
  if (w is ElementHost) return w.children;
  if (w is Menu) return w.items;
  if (w is ContextMenu) return w.items;
  if (w is Dialog) return w.buttons;
  return const [];
}
