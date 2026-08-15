/// Hoverable mixin — standardises hover state for interactive widgets.
///
/// Apply with `mixin Hoverable on Widget` to get automatic hover tracking
/// that sets/un-sets the `'hover'` pseudo-class and triggers repaint.
///
/// ```dart
/// class MyButton extends Widget with Hoverable { … }
/// ```
library;

import '../widget.dart';
import '../interaction.dart';

/// Adds hover state tracking to a [Widget].
///
/// Provides [isHovered] and automatically wires [onMouseEnter]/[onMouseLeave]
/// to update the `'hover'` pseudo-class and call [onHoverChanged].
mixin Hoverable on Widget {
  @override
  void initState() {
    super.initState();
    onMouseEnter ??= _onEnter;
    onMouseLeave ??= _onLeave;
  }

  void _onEnter() {
    if (setInteractionState(WidgetState.hovered, true)) {
      onHoverChanged(true);
    }
  }

  void _onLeave() {
    if (setInteractionState(WidgetState.hovered, false)) {
      onHoverChanged(false);
    }
  }

  /// Updates hover state from a widget/window focus manager.
  ///
  /// This is public because widgets live in separate Dart libraries from the
  /// mixin and should not reach into its private callbacks.
  void setHovering(bool hovering) {
    if (hovering) {
      _onEnter();
    } else {
      _onLeave();
    }
  }

  /// Called when hover state changes. Override to customise.
  /// Default implementation triggers a repaint via [setState].
  @override
  void onHoverChanged(bool hovering) {
    setState(() {});
  }
}
