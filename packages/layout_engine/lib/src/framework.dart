/// Widget framework: StatefulWidget, StatelessWidget, State, InheritedWidget.
///
/// Framework-agnostic widget types for the Element tree.
library;

import 'element_tree.dart' show BuildContext;

/// Base class for widgets in the Element tree.
///
/// Framework-agnostic. Extend this for widgets that participate in the
/// element lifecycle. The [key] identifies widget instances across rebuilds.
/// Non-null keys with the same [runtimeType] preserve state across position
/// changes. Keys can be any object — strings, ints, or custom identifiers.
abstract class ElementWidget {
  final Object? key;
  const ElementWidget({this.key});

  /// Whether [newWidget] can be used to update an element created with
  /// [oldWidget]. Same runtimeType and matching keys = can update.
  static bool canUpdate(ElementWidget oldWidget, ElementWidget newWidget) {
    if (oldWidget.runtimeType != newWidget.runtimeType) return false;
    if (oldWidget.key == null && newWidget.key == null) return true;
    if (oldWidget.key == null || newWidget.key == null) return false;
    return oldWidget.key == newWidget.key;
  }
}

/// A widget that builds from configuration with no mutable state.
abstract class StatelessWidget extends ElementWidget {
  ElementWidget build(BuildContext context);
  const StatelessWidget({super.key});
}

/// A widget that has mutable state managed by a [State] object.
abstract class StatefulWidget extends ElementWidget {
  State createState();
  const StatefulWidget({super.key});
}

/// Mutable state for a [StatefulWidget].
abstract class State<T extends StatefulWidget> {
  /// Internal: set by StatefulElement to trigger rebuild.
  void Function()? markNeedsBuild;

  /// Internal: set by StatefulElement.
  T? widgetOverride;

  /// Internal: set by StatefulElement.
  BuildContext? contextOverride;

  /// The current widget configuration.
  T get widget => widgetOverride!;

  /// The build context.
  BuildContext get context => contextOverride!;

  /// Whether this state is mounted in the element tree.
  bool get mounted => markNeedsBuild != null;

  /// Called once when the state is first created.
  void initState() {}

  /// Called when the widget configuration changes.
  void didUpdateWidget(covariant T oldWidget) {}

  /// Called when the state is permanently removed.
  void dispose() {}

  /// Build the widget subtree.
  ElementWidget build(BuildContext context);

  /// Notify the framework that internal data changed.
  void setState(void Function() fn) {
    fn();
    markNeedsBuild?.call();
  }
}

/// An inherited widget that propagates data down the tree.
abstract class InheritedWidget extends ElementWidget {
  final ElementWidget child;
  InheritedWidget({required this.child, super.key});

  bool updateShouldNotify(covariant InheritedWidget oldWidget);
}
