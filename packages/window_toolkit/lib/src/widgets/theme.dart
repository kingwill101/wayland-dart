/// Theme inherited widget — propagates palette data down the widget tree.
///
/// Child widgets access the theme via [Theme.of] and automatically rebuild
/// when the theme data changes.
///
/// ```dart
/// Theme(data: Palette.current.active, child: VBox(children: [...]))
/// // In any descendant:
/// final bg = Theme.of(context)?.window ?? defaultColor;
/// ```
import 'package:layout_engine/layout_engine.dart' show BuildContext, ElementWidget, InheritedWidget;

import '../palette.dart';

/// Inherited theme that propagates [ColorGroup] data down the element tree.
/// Dependents auto-rebuild when the theme data changes.
class Theme extends InheritedWidget {
  final ColorGroup data;

  Theme({
    required this.data,
    required ElementWidget child,
  }) : super(child: child);

  /// Look up the nearest Theme from a build context.
  static ColorGroup? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<Theme>()?.data;
  }

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) {
    return (oldWidget as Theme).data != data;
  }
}
