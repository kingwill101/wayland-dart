/// Widget framework: StatefulWidget, StatelessWidget, State, InheritedWidget.
///
/// Framework-agnostic widget types for the Element tree.
library;

import 'element_tree.dart' show BuildContext;

/// A key identifies a widget instance across rebuilds.
///
/// Two widgets with the same [runtimeType] and matching [WidgetKey]s
/// preserve the element's state even when their position in the tree
/// changes.
class WidgetKey {
  final Object? value;
  const WidgetKey(this.value);

  @override
  bool operator ==(Object other) => other is WidgetKey && value == other.value;
  @override
  int get hashCode => value.hashCode;
}

/// A key that uses a value of type [T] for identity.
class ValueWidgetKey<T> extends WidgetKey {
  final T id;
  const ValueWidgetKey(this.id) : super(id);
}

/// A key that is unique across the program — never matches another key.
class UniqueWidgetKey extends WidgetKey {
  static int _counter = 0;
  final int _uid = _counter++;
  UniqueWidgetKey() : super(null);

  @override
  bool operator ==(Object other) => identical(this, other);
  @override
  int get hashCode => _uid;
}

/// Base class for widgets in the Element tree.
///
/// Framework-agnostic. Extend this for widgets that participate in the
/// element lifecycle. The [key] identifies widget instances across rebuilds.
/// Non-null keys with the same [runtimeType] preserve state across position
/// changes.
abstract class ElementWidget {
  final WidgetKey? key;
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
