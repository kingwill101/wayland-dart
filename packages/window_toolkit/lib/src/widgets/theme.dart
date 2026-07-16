/// Theme inherited widget — propagates palette/colors down the widget tree.
///
/// ```dart
/// Theme(
///   data: myDarkPalette,
///   child: VBox(children: [ ... ]),
/// )
/// ```
///
/// Child widgets access the theme via:
/// ```dart
/// final theme = context.dependOnInheritedWidgetOfExactType<Theme>();
/// final bg = theme?.data.window ?? defaultColor;
/// ```
import 'package:layout_engine/layout_engine.dart' show BuildContext, ElementWidget, InheritedWidget;

import '../palette.dart';

/// Inherited theme that propagates [ColorGroup] data down the element tree.
class Theme extends InheritedWidget {
  final ColorGroup? data;

  Theme({
    this.data,
    required ElementWidget child,
  }) : super(child: child);

  /// Look up the nearest Theme from a build context.
  static ColorGroup? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<Theme>()?.data;
  }

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) {
    final old = oldWidget as Theme;
    // Simple comparison — notifies on any change.
    return data != old.data;
  }
}
